import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Source picker
            Picker("Source", selection: $controller.sourceType) {
                ForEach(CalendarSourceType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Divider()

            // Source-specific status & action
            switch controller.sourceType {
            case .apple:
                if controller.hasAppleAccess {
                    Label("Apple Calendar connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button {
                        controller.requestAppleAccess()
                    } label: {
                        Label("Grant Apple Calendar access", systemImage: "calendar")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .google:
                if controller.isGoogleAuthenticated {
                    Label("Google Calendar connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Button {
                        controller.signOut()
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        controller.signIn()
                    } label: {
                        Label("Connect Google Calendar", systemImage: "calendar")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Divider()

            Button {
                controller.testAirplane()
            } label: {
                Label("Test airplane", systemImage: "airplane")
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit MeetingBuddy", systemImage: "power")
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 280)
    }
}
