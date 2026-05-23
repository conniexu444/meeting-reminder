import SwiftUI

@main
struct MeetingBuddyApp: App {
    @StateObject private var controller = AppController()

    var body: some Scene {
        // Lives in the menu bar only — no Dock icon needed (set LSUIElement in Info.plist)
        MenuBarExtra {
            MenuBarView()
                .environmentObject(controller)
        } label: {
            // Fills with yellow when a meeting is imminent (handled by AppController in future)
            Image(systemName: "airplane")
        }
        .menuBarExtraStyle(.window)
    }
}
