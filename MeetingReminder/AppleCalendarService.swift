import Foundation
import EventKit

final class AppleCalendarService: CalendarSourceProvider {
    private let store = EKEventStore()

    /// True if we currently have full read access to calendar events.
    var hasAccess: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    /// Prompts the user for calendar access. Returns whether access was granted.
    func requestAccess() async -> Bool {
        (try? await store.requestFullAccessToEvents()) ?? false
    }

    func fetchUpcomingEvents() async throws -> [CalendarEvent] {
        let now          = Date()
        let oneHourLater = now.addingTimeInterval(3_600)
        let predicate    = store.predicateForEvents(withStart: now,
                                                    end:       oneHourLater,
                                                    calendars: nil)
        let ekEvents = store.events(matching: predicate)
        return ekEvents.map { e in
            CalendarEvent(
                id:        e.eventIdentifier ?? UUID().uuidString,
                title:     e.title ?? "Untitled Meeting",
                startDate: e.startDate,
                endDate:   e.endDate
            )
        }
    }
}
