import Foundation

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
}

protocol CalendarSourceProvider: AnyObject {
    func fetchUpcomingEvents() async throws -> [CalendarEvent]
}
