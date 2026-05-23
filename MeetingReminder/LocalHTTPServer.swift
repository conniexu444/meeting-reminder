import Foundation
import Network

// Spins up a one-shot localhost server to catch the OAuth redirect from the browser.
final class LocalHTTPServer: @unchecked Sendable {
    private var listener: NWListener?
    private let port: NWEndpoint.Port
    private let onCode: @Sendable (String) -> Void

    init(port: UInt16 = Config.oauthPort, onCode: @escaping @Sendable (String) -> Void) {
        self.port = NWEndpoint.Port(rawValue: port)!
        self.onCode = onCode
    }

    func start() {
        guard let listener = try? NWListener(using: .tcp, on: port) else { return }
        self.listener = listener

        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: .global(qos: .utility))
            self?.read(connection)
        }
        listener.start(queue: .global(qos: .utility))
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    // MARK: Private

    private func read(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, _, _ in
            guard let self,
                  let data, !data.isEmpty,
                  let request = String(data: data, encoding: .utf8),
                  let code = self.extractCode(from: request) else { return }

            let html = "<html><body style='font-family:system-ui;padding:40px'>" +
                       "<h2>✅ MeetingReminder connected!</h2><p>You can close this tab.</p></body></html>"
            let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n\(html)"
            connection.send(content: Data(response.utf8),
                            completion: .contentProcessed { _ in connection.cancel() })
            self.stop()
            self.onCode(code)
        }
    }

    private func extractCode(from request: String) -> String? {
        guard let line = request.components(separatedBy: "\r\n").first else { return nil }
        let parts = line.components(separatedBy: " ")
        guard parts.count >= 2 else { return nil }
        return URLComponents(string: "http://localhost" + parts[1])?
            .queryItems?.first(where: { $0.name == "code" })?.value
    }
}
