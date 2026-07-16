import Foundation
import AppKit
import Combine

// Central coordinator: owns the Apple Calendar service + poller, and triggers the airplane.
@MainActor
final class AppController: ObservableObject {
    @Published var hasAppleAccess: Bool = false
    @Published var flightDuration: Double {
        didSet { UserDefaults.standard.set(flightDuration, forKey: "flightDuration") }
    }

    /// Preset speeds (seconds for the plane to cross the screen).
    static let slowSpeed:   Double = 22
    static let normalSpeed: Double = 14
    static let fastSpeed:   Double = 8

    private let appleService = AppleCalendarService()
    private var poller: CalendarPoller?
    private var overlayWindows: [AirplaneOverlayWindow] = []

    init() {
        let saved = UserDefaults.standard.double(forKey: "flightDuration")
        self.flightDuration = saved > 0 ? saved : Self.normalSpeed

        hasAppleAccess = appleService.hasAccess
        startPollingIfReady()
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

    /// Manual trigger — shows the airplane immediately with a fake meeting.
    func testAirplane() {
        let fake = CalendarEvent(
            id:        UUID().uuidString,
            title:     "Test Meeting",
            startDate: Date().addingTimeInterval(300),
            endDate:   Date().addingTimeInterval(1800)
        )
        showAirplane(for: fake, minutesUntil: 5)
    }

    // MARK: Private

    private func startPollingIfReady() {
        poller?.stop()
        poller = nil
        guard hasAppleAccess else { return }

        let p = CalendarPoller(service: appleService)
        p.onMeetingSoon = { [weak self] event, minutes in
            self?.showAirplane(for: event, minutesUntil: minutes)
        }
        p.start()
        poller = p
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
}
