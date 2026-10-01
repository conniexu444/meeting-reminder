import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if controller.hasAppleAccess {
                Label("Calendar connected", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                if let meeting = controller.nextMeeting,
                   let mins = controller.nextMeetingMinutes {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next up")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(meeting.title)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(2)
                        Text(mins <= 0 ? "starting now" : "in \(mins) min")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No meetings in the next hour")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    controller.requestAppleAccess()
                } label: {
                    Label("Grant Calendar access", systemImage: "calendar")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            // Alert timing — how early the airplane flies
            VStack(alignment: .leading, spacing: 4) {
                Text("Remind me")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Picker("Remind me", selection: $controller.alertMinutesBefore) {
                    Text("3 min").tag(AppController.alertSoon)
                    Text("5 min").tag(AppController.alertNormal)
                    Text("10 min").tag(AppController.alertEarly)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Divider()

            // Speed picker — how long the plane takes to cross the screen
            VStack(alignment: .leading, spacing: 4) {
                Text("Plane speed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Picker("Plane speed", selection: $controller.flightDuration) {
                    Text("Slow").tag(AppController.slowSpeed)
                    Text("Normal").tag(AppController.normalSpeed)
                    Text("Fast").tag(AppController.fastSpeed)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Divider()

            Toggle("Start at login", isOn: Binding(
                get: { controller.launchAtLogin },
                set: { controller.setLaunchAtLogin($0) }
            ))
            .toggleStyle(.switch)
            .font(.system(size: 13))

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
                Label("Quit MeetingReminder", systemImage: "power")
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 280)
    }
}
