// MARK: - Paste your Google OAuth credentials here
//
// Setup:
//   1. Follow GOOGLE_SETUP.md to create a Google Cloud project and get an
//      OAuth 2.0 Client ID + Secret for a "Desktop app" client.
//   2. Copy this file to `Config.swift` in the same directory:
//        cp MeetingBuddy/Config.example.swift MeetingBuddy/Config.swift
//   3. Open the new Config.swift and replace the placeholder values below.
//
// `Config.swift` is git-ignored, so your secrets stay local.
enum Config {
    static let googleClientID     = "YOUR_CLIENT_ID.apps.googleusercontent.com"
    static let googleClientSecret = "YOUR_CLIENT_SECRET"
    static let redirectURI        = "http://localhost:8080/callback"
    static let oauthPort: UInt16  = 8080

    // How many minutes before a meeting to show the alert (default 5)
    static let alertMinutesBefore = 5
    // Window to consider "≈5 min away": trigger when 4–6 min remain
    static let alertWindowLow  = alertMinutesBefore - 1
    static let alertWindowHigh = alertMinutesBefore + 1
}
