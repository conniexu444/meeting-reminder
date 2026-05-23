import Foundation
import AppKit

@MainActor
final class GoogleOAuth {
    private(set) var isAuthenticated: Bool = false
    var onAuthChanged: ((Bool) -> Void)?

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date?
    private var server: LocalHTTPServer?

    private let scope = "https://www.googleapis.com/auth/calendar.readonly"

    init() {
        loadStoredTokens()
    }

    // MARK: Public

    func signIn() {
        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            .init(name: "client_id",     value: Config.googleClientID),
            .init(name: "redirect_uri",  value: Config.redirectURI),
            .init(name: "response_type", value: "code"),
            .init(name: "scope",         value: scope),
            .init(name: "access_type",   value: "offline"),
            .init(name: "prompt",        value: "consent"),
            .init(name: "state",         value: UUID().uuidString),
        ]
        server = LocalHTTPServer { code in
            DispatchQueue.main.async { [weak self] in
                Task { await self?.exchange(code: code) }
            }
        }
        server?.start()
        NSWorkspace.shared.open(comps.url!)
    }

    func signOut() {
        accessToken  = nil
        refreshToken = nil
        tokenExpiry  = nil
        UserDefaults.standard.removeObject(forKey: "mb_accessToken")
        UserDefaults.standard.removeObject(forKey: "mb_refreshToken")
        UserDefaults.standard.removeObject(forKey: "mb_tokenExpiry")
        setAuthenticated(false)
    }

    /// Returns a valid access token, refreshing if necessary.
    func getValidToken() async throws -> String {
        if let token = accessToken, let expiry = tokenExpiry, expiry > Date() {
            return token
        }
        return try await refresh()
    }

    // MARK: Private

    private func exchange(code: String) async {
        let body: [String: String] = [
            "code":          code,
            "client_id":     Config.googleClientID,
            "client_secret": Config.googleClientSecret,
            "redirect_uri":  Config.redirectURI,
            "grant_type":    "authorization_code",
        ]
        do {
            let token = try await post(to: "https://oauth2.googleapis.com/token", fields: body)
            store(token: token, keepRefresh: token.refreshToken)
            setAuthenticated(true)
        } catch {
            // Auth exchange failed — leave state untouched
        }
    }

    private func refresh() async throws -> String {
        guard let rt = refreshToken else { throw OAuthError.notAuthenticated }
        let body: [String: String] = [
            "refresh_token": rt,
            "client_id":     Config.googleClientID,
            "client_secret": Config.googleClientSecret,
            "grant_type":    "refresh_token",
        ]
        let token = try await post(to: "https://oauth2.googleapis.com/token", fields: body)
        store(token: token, keepRefresh: nil)
        return token.accessToken
    }

    private func post(to urlString: String, fields: [String: String]) async throws -> TokenResponse {
        var req = URLRequest(url: URL(string: urlString)!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = fields.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
                             .joined(separator: "&")
                             .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func store(token: TokenResponse, keepRefresh: String?) {
        accessToken = token.accessToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(token.expiresIn) - 60)
        if let rt = keepRefresh { refreshToken = rt }

        UserDefaults.standard.set(accessToken, forKey: "mb_accessToken")
        UserDefaults.standard.set(tokenExpiry, forKey: "mb_tokenExpiry")
        if let rt = keepRefresh {
            UserDefaults.standard.set(rt, forKey: "mb_refreshToken")
        }
    }

    private func loadStoredTokens() {
        accessToken  = UserDefaults.standard.string(forKey: "mb_accessToken")
        refreshToken = UserDefaults.standard.string(forKey: "mb_refreshToken")
        tokenExpiry  = UserDefaults.standard.object(forKey: "mb_tokenExpiry") as? Date
        isAuthenticated = accessToken != nil
    }

    private func setAuthenticated(_ value: Bool) {
        isAuthenticated = value
        onAuthChanged?(value)
    }
}
