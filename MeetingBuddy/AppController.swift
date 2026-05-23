import Foundation
import AppKit
import Combine

// Central coordinator: owns both calendar sources and the poller.
// Lets the user switch between Apple Calendar (EventKit) and Google Calendar.
@MainActor
final class AppController: ObservableObject {
    @Published var sourceType: CalendarSourceType {
        didSet {
            UserDefaults.standard.set(sourceType.rawValue, forKey: "mb_sourceType")
            refreshPoller()
        }
    }
    @Published var isGoogleAuthenticated: Bool = false
    @Published var hasAppleAccess: Bool        = false

    let oauth: GoogleOAuth
    private let appleService: AppleCalendarService
    private var poller: CalendarPoller?
    private var overlayWindows: [AirplaneOverlayWindow] = []

    init() {
        let raw = UserDefaults.standard.string(forKey: "mb_sourceType") ?? CalendarSourceType.apple.rawValue
        sourceType = CalendarSourceType(rawValue: raw) ?? .apple

        oauth        = GoogleOAuth()
        appleService = AppleCalendarService()

        isGoogleAuthenticated = oauth.isAuthenticated
        hasAppleAccess        = appleService.hasAccess

        oauth.onAuthChanged = { [weak self] authenticated in
            DispatchQueue.main.async {
                self?.isGoogleAuthenticated = authenticated
                self?.refreshPoller()
            }
        }

        refreshPoller()
    }

    // MARK: Public

    func signIn()  { oauth.signIn() }
    func signOut() { oauth.signOut() }

    func requestAppleAccess() {
        Task {
            let granted = await appleService.requestAccess()
            await MainActor.run {
                self.hasAppleAccess = granted
                self.refreshPoller()
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

    private func activeService() -> (any CalendarSourceProvider)? {
        switch sourceType {
        case .apple:  return hasAppleAccess        ? appleService                          : nil
        case .google: return isGoogleAuthenticated ? GoogleCalendarService(oauth: oauth)   : nil
        }
    }

    private func refreshPoller() {
        poller?.stop()
        poller = nil

        guard let service = activeService() else { return }

        let p = CalendarPoller(service: service)
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
