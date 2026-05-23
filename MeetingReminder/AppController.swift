import Foundation
import AppKit
import Combine

// Central coordinator: owns the Apple Calendar service + poller, and triggers the airplane.
@MainActor
final class AppController: ObservableObject {
    @Published var hasAppleAccess: Bool = false

    private let appleService = AppleCalendarService()
    private var poller: CalendarPoller?
    private var overlayWindows: [AirplaneOverlayWindow] = []

    init() {
        hasAppleAccess = appleService.hasAccess
        startPollingIfReady()
    }

    // MARK: Public

    func requestAppleAccess() {
        Task {
            let granted = await appleService.requestAccess()
            await MainActor.run {
                self.hasAppleAccess = granted
                self.startPollingIfReady()
            }
        }
    }

    /// Manual trigger — shows the airplane immediately with a fake meeting.
    func testAirplane() {
        let fake = CalendarEvent(
            id:        UUID().uuidString,
            title:     "Meeting with Andrew",
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
        DispatchQueue.main.async {
            let window = AirplaneOverlayWindow(meetingTitle: event.title, minutesUntil: minutesUntil)
            window.makeKeyAndOrderFront(nil)
            self.overlayWindows.append(window)

            // Release after animation finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 15.5) {
                self.overlayWindows.removeAll { $0 === window }
                window.close()
            }
        }
    }
}
