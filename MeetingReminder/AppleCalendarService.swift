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
                title:     bannerTitle(for: e),
                startDate: e.startDate,
                endDate:   e.endDate
            )
        }
    }

    /// Prefer "Meeting with <names>" when the event has invitees besides you;
    /// fall back to the event title otherwise.
    private func bannerTitle(for event: EKEvent) -> String {
        let fallback = event.title ?? "Untitled Meeting"

        let names = (event.attendees ?? [])
            .filter { !$0.isCurrentUser }
            .compactMap { participant -> String? in
                guard let name = participant.name, !name.isEmpty else { return nil }
                return name
            }

        guard !names.isEmpty else { return fallback }

        switch names.count {
        case 1:  return "Meeting with \(names[0])"
        case 2:  return "Meeting with \(names[0]) and \(names[1])"
        default: return "Meeting with \(names[0]), \(names[1]) +\(names.count - 2) more"
        }
    }
}
