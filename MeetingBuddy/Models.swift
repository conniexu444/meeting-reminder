import Foundation

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
}

// MARK: - Google Calendar REST API shapes

struct EventsListResponse: Codable {
    let items: [EventItem]?
}

struct EventItem: Codable {
    let id: String?
    let summary: String?
    let start: EventDateTime?
    let end: EventDateTime?
}

struct EventDateTime: Codable {
    let dateTime: String?   // RFC3339 for timed events
    let date: String?       // date-only for all-day events
}

// MARK: - OAuth token shapes

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn    = "expires_in"
        case tokenType    = "token_type"
    }
}

enum OAuthError: Error {
    case notAuthenticated
    case tokenRefreshFailed
}
