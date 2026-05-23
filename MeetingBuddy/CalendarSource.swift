import Foundation

enum CalendarSourceType: String, CaseIterable, Identifiable {
    case apple
    case google

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple:  "Apple Calendar"
        case .google: "Google Calendar"
        }
    }
}

protocol CalendarSourceProvider: AnyObject {
    func fetchUpcomingEvents() async throws -> [CalendarEvent]
}
