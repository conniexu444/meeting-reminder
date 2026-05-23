import Foundation

@MainActor
final class CalendarPoller {
    var onMeetingSoon: ((CalendarEvent, Int) -> Void)?

    private let service: any CalendarSourceProvider
    private var timer: Timer?
    // Persists across poll cycles so we don't fire the same alert twice
    private var notifiedIDs: Set<String> = []

    init(service: any CalendarSourceProvider) {
        self.service = service
    }

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            DispatchQueue.main.async { [weak self] in self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: Private

    private func poll() {
        Task {
            guard let events = try? await service.fetchUpcomingEvents() else { return }

            let now = Date()
            for event in events {
                let minutes = Int(event.startDate.timeIntervalSince(now) / 60)
                guard minutes >= Config.alertWindowLow,
                      minutes <= Config.alertWindowHigh,
                      !notifiedIDs.contains(event.id) else { continue }

                notifiedIDs.insert(event.id)
                onMeetingSoon?(event, minutes)
            }
        }
    }
}
