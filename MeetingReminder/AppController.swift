import Foundation
import AppKit
import Combine
import os
import ServiceManagement

// Central coordinator: owns the Apple Calendar service + poller, and triggers the airplane and bumblebee.
@MainActor
final class AppController: ObservableObject {
    @Published var hasAppleAccess: Bool = false
    @Published var flightDuration: Double {
        didSet { UserDefaults.standard.set(flightDuration, forKey: "flightDuration") }
    }
    /// Minutes before a meeting to fly the airplane banner. Persisted.
    @Published var alertMinutesBefore: Double {
        didSet {
            UserDefaults.standard.set(alertMinutesBefore, forKey: "alertMinutesBefore")
            poller?.alertMinutesBefore = alertMinutesBefore
        }
    }
    @Published var launchAtLogin: Bool = false
    /// Soonest upcoming meeting within the next hour (if any).
    @Published var nextMeeting: CalendarEvent? = nil
    @Published var nextMeetingMinutes: Int? = nil

    /// Preset speeds (seconds for the plane to cross the screen).
    static let slowSpeed:   Double = 22
    static let normalSpeed: Double = 14
    static let fastSpeed:   Double = 8

    /// Preset alert lead times (minutes).
    static let alertSoon:   Double = 3
    static let alertNormal: Double = 5
    static let alertEarly:  Double = 10

    private let appleService = AppleCalendarService()
    private var poller: CalendarPoller?
    private var overlayWindows: [AirplaneOverlayWindow] = []
    private var nextMeetingTimer: Timer?

    /// True while a bumblebee is waiting for the flower (or the menu) to acknowledge.
    @Published var bumblebeeActive: Bool = false
    private var beeWindow: BumblebeeCueWindow?
    private var flowerWindows: [FlowerAckWindow] = []
    private var activeBeeEventID: String?
    private var beeIsTest = false
    private var beeGeneration = 0
    private var acknowledgedBeeIDs: Set<String> = []
    private var acknowledgedBeeOrder: [String] = []
    private let log = Logger(subsystem: "com.connie.MeetingReminder", category: "Bumblebee")

    init() {
        let savedSpeed = UserDefaults.standard.double(forKey: "flightDuration")
        self.flightDuration = savedSpeed > 0 ? savedSpeed : Self.normalSpeed

        let savedAlert = UserDefaults.standard.double(forKey: "alertMinutesBefore")
        self.alertMinutesBefore = savedAlert > 0 ? savedAlert : Self.alertNormal

        launchAtLogin = SMAppService.mainApp.status == .enabled

        hasAppleAccess = appleService.hasAccess
        startPollingIfReady()
        startNextMeetingRefresh()
    }

    // MARK: Public

    func requestAppleAccess() {
        // macOS 26: TCC prompt won't appear for menu-bar-only apps unless the app
        // is the active application first. Activate, then request.
        NSApplication.shared.activate(ignoringOtherApps: true)
        Task {
            let granted = await appleService.requestAccess()
            await MainActor.run {
                self.hasAppleAccess = granted
                self.startPollingIfReady()
                self.refreshNextMeeting()
                if !granted {
                    // If the prompt still didn't appear (macOS 26 known issue),
                    // open System Settings → Privacy → Calendars as fallback.
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }

    /// Enable or disable launching the app automatically at login.
    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Failed to update launch-at-login: \(error.localizedDescription)")
        }
        // Re-read the real status; the request may have failed or been overridden.
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    /// Manual trigger — shows the airplane immediately with a fake meeting.
    func testAirplane() {
        let mins = Int(alertMinutesBefore)
        let fake = CalendarEvent(
            id:        UUID().uuidString,
            title:     "Test Meeting",
            startDate: Date().addingTimeInterval(Double(mins) * 60),
            endDate:   Date().addingTimeInterval(1800)
        )
        showAirplane(for: fake, minutesUntil: mins)
    }

    /// Manual trigger — bee follows the pointer until the flower is pressed.
    func testBumblebee() {
        let fake = CalendarEvent(
            id:        "bumblebee-test-\(UUID().uuidString)",
            title:     "Test Meeting",
            startDate: Date().addingTimeInterval(BumblebeeCue.leadMinutes * 60),
            endDate:   Date().addingTimeInterval(BumblebeeCue.leadMinutes * 60 + 1_800)
        )
        showBumblebee(for: fake, isTest: true)
    }

    /// Stops the cue for the meeting that is currently showing.
    func acknowledgeBumblebee() {
        hideBumblebee(recordAck: true)
    }

    // MARK: Private

    private func startPollingIfReady() {
        poller?.stop()
        poller = nil
        guard hasAppleAccess else { return }

        let p = CalendarPoller(service: appleService, alertMinutesBefore: alertMinutesBefore)
        p.onMeetingSoon = { [weak self] event, minutes in
            self?.showAirplane(for: event, minutesUntil: minutes)
        }
        p.start()
        poller = p
    }

    private func startNextMeetingRefresh() {
        refreshNextMeeting()
        nextMeetingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            DispatchQueue.main.async { [weak self] in self?.refreshNextMeeting() }
        }
    }

    private func refreshNextMeeting() {
        guard hasAppleAccess else {
            nextMeeting = nil
            nextMeetingMinutes = nil
            return
        }
        Task { @MainActor in
            do {
                let events = try await appleService.fetchUpcomingEvents()
                let now = Date()
                let upcoming = events
                    .filter { $0.startDate > now }
                    .sorted { $0.startDate < $1.startDate }
                if let first = upcoming.first {
                    let minutes = first.startDate.timeIntervalSince(now) / 60
                    nextMeeting = first
                    nextMeetingMinutes = Int(ceil(minutes))
                    updateBumblebeeCue(for: first, minutesUntil: minutes)
                } else {
                    nextMeeting = nil
                    nextMeetingMinutes = nil
                    updateBumblebeeCue(for: nil, minutesUntil: nil)
                }
            } catch {
                // Leave an in-progress bee alone. A transient fetch failure
                // should not dismiss a reminder that has not been acknowledged.
                nextMeeting = nil
                nextMeetingMinutes = nil
            }
        }
    }

    private func showAirplane(for event: CalendarEvent, minutesUntil: Int) {
        let duration = flightDuration
        DispatchQueue.main.async {
            // Spawn one overlay per screen so the animation plays on every display
            let screens = NSScreen.screens.isEmpty ? [NSScreen.main].compactMap { $0 } : NSScreen.screens
            for screen in screens {
                let window = AirplaneOverlayWindow(
                    meetingTitle:   event.title,
                    minutesUntil:   minutesUntil,
                    flightDuration: duration,
                    screen:         screen
                )
                window.makeKeyAndOrderFront(nil)
                self.overlayWindows.append(window)

                // Release shortly after the animation finishes (fade-out is 0.6s)
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1.5) {
                    self.overlayWindows.removeAll { $0 === window }
                    window.close()
                }
            }
        }
    }

    /// Arms the bee about 3 minutes before the next meeting and leaves it up
    /// until that meeting is acknowledged or its start time passes.
    /// The airplane's Remind me picker does not change this lead time.
    private func updateBumblebeeCue(for event: CalendarEvent?, minutesUntil: Double?) {
        guard !beeIsTest else { return }

        guard let event, let minutesUntil else {
            if bumblebeeActive { hideBumblebee(recordAck: false) }
            return
        }

        if acknowledgedBeeIDs.contains(event.id) {
            if activeBeeEventID == event.id { hideBumblebee(recordAck: false) }
            return
        }

        // Already cueing this meeting — keep hovering until ack or start.
        if activeBeeEventID == event.id { return }

        if bumblebeeActive { hideBumblebee(recordAck: false) }

        guard BumblebeeCue.isInsideTriggerWindow(minutesUntil: minutesUntil) else { return }
        showBumblebee(for: event, isTest: false)
    }

    private func showBumblebee(for event: CalendarEvent, isTest: Bool) {
        if !isTest, activeBeeEventID == event.id, bumblebeeActive { return }

        hideBumblebee(recordAck: false)
        activeBeeEventID = event.id
        beeIsTest = isTest
        bumblebeeActive = true
        beeGeneration += 1
        let generation = beeGeneration

        if isTest {
            log.info("Bumblebee test cue")
        } else {
            log.info("Bumblebee cue for '\(event.title)'")
        }

        DispatchQueue.main.async { [weak self] in
            guard let self, self.beeGeneration == generation else { return }

            let bee = BumblebeeCueWindow()
            bee.startFollowingCursor()
            bee.orderFrontRegardless()
            self.beeWindow = bee

            let screens = NSScreen.screens.isEmpty ? [NSScreen.main].compactMap { $0 } : NSScreen.screens
            for screen in screens where screen.visibleFrame.width > 80 && screen.visibleFrame.height > 80 {
                let flower = FlowerAckWindow(meetingTitle: event.title, screen: screen) { [weak self] in
                    Task { @MainActor in
                        self?.acknowledgeBumblebee()
                    }
                }
                flower.orderFrontRegardless()
                self.flowerWindows.append(flower)
            }
        }
    }

    private func hideBumblebee(recordAck: Bool) {
        beeGeneration += 1
        if recordAck, !beeIsTest, let id = activeBeeEventID {
            acknowledgedBeeIDs.insert(id)
            acknowledgedBeeOrder.append(id)
            if acknowledgedBeeOrder.count > 200 {
                let evicted = acknowledgedBeeOrder.removeFirst()
                acknowledgedBeeIDs.remove(evicted)
            }
            log.info("Bumblebee acknowledged")
        }

        activeBeeEventID = nil
        beeIsTest = false
        bumblebeeActive = false
        beeWindow?.stopFollowingCursor()
        beeWindow?.close()
        beeWindow = nil
        for window in flowerWindows { window.close() }
        flowerWindows.removeAll()
    }
}
