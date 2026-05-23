import SwiftUI

struct AirplaneView: View {
    let meetingTitle: String
    let minutesUntil: Int

    @State private var xOffset: CGFloat
    @State private var opacity: Double = 1.0

    private var screenWidth: CGFloat { NSScreen.main?.frame.width ?? 1_440 }
    private let flightDuration: Double = 14.0
    // Generous estimate of HStack content width (plane + rope + banner)
    private let estimatedContentWidth: CGFloat = 600

    init(meetingTitle: String, minutesUntil: Int) {
        self.meetingTitle = meetingTitle
        self.minutesUntil = minutesUntil
        _xOffset = State(initialValue: -650)   // start fully off-left (= -estimatedContentWidth - small buffer)
    }

    var body: some View {
        HStack(spacing: -10) {
            // Text drives the size; the (already-trimmed) banner stretches to fit behind it
            Text("\(meetingTitle) in \(minutesUntil) min")
                .font(.custom("Comic Sans MS", size: 28))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 50)
                .padding(.vertical, 22)
                .background(
                    Image("banner")
                        .resizable()
                )

            // Custom airplane asset — drawn behind the banner so the rope tucks under
            Image("airplane")
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
                .zIndex(-1)
        }
        .fixedSize()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .offset(x: xOffset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.linear(duration: flightDuration)) {
                xOffset = screenWidth + 50   // end fully off-right
            }
            // Fade out in the last half-second
            DispatchQueue.main.asyncAfter(deadline: .now() + flightDuration - 0.6) {
                withAnimation(.easeIn(duration: 0.6)) {
                    opacity = 0
                }
            }
        }
    }
}

#Preview {
    AirplaneView(meetingTitle: "Weekly Standup", minutesUntil: 5)
        .frame(width: 1000, height: 100)
        .background(Color.gray.opacity(0.2))
}
