import Foundation

final class GoogleCalendarService: CalendarSourceProvider {
    private let oauth: GoogleOAuth

    init(oauth: GoogleOAuth) {
        self.oauth = oauth
    }

    /// Fetches events starting in the next 60 minutes from the primary calendar.
    func fetchUpcomingEvents() async throws -> [CalendarEvent] {
        let token = try await oauth.getValidToken()

        let now          = Date()
        let oneHourLater = now.addingTimeInterval(3_600)
        let fmt          = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]

        var comps = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        comps.queryItems = [
            .init(name: "timeMin",       value: fmt.string(from: now)),
            .init(name: "timeMax",       value: fmt.string(from: oneHourLater)),
            .init(name: "singleEvents",  value: "true"),
            .init(name: "orderBy",       value: "startTime"),
            .init(name: "maxResults",    value: "20"),
        ]

        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: req)
        let response  = try JSONDecoder().decode(EventsListResponse.self, from: data)

        return (response.items ?? []).compactMap { item -> CalendarEvent? in
            guard let startStr = item.start?.dateTime ?? item.start?.date,
                  let start    = parseDate(startStr),
                  let endStr   = item.end?.dateTime   ?? item.end?.date,
                  let end      = parseDate(endStr)
            else { return nil }

            return CalendarEvent(
                id:        item.id ?? UUID().uuidString,
                title:     item.summary ?? "Untitled Meeting",
                startDate: start,
                endDate:   end
            )
        }
    }

    private func parseDate(_ string: String) -> Date? {
        let full = ISO8601DateFormatter()
        full.formatOptions = [.withInternetDateTime]
        if let d = full.date(from: string) { return d }

        let dateOnly = ISO8601DateFormatter()
        dateOnly.formatOptions = [.withFullDate]
        return dateOnly.date(from: string)
    }
}
