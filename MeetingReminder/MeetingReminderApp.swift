import SwiftUI

@main
struct MeetingReminderApp: App {
    @StateObject private var controller = AppController()

    var body: some Scene {
        // Lives in the menu bar only — no Dock icon needed (set LSUIElement in Info.plist)
        MenuBarExtra {
            MenuBarView()
                .environmentObject(controller)
        } label: {
            Image("menubar")
        }
        .menuBarExtraStyle(.window)
    }
}
