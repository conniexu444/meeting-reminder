import SwiftUI

struct AirplaneView: View {
    let meetingTitle: String
    let minutesUntil: Int
    let flightDuration: Double
    let screenWidth: CGFloat

    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var contentWidth: CGFloat = 0  // measured at runtime via GeometryReader

    init(meetingTitle: String, minutesUntil: Int, flightDuration: Double, screenWidth: CGFloat = NSScreen.main?.frame.width ?? 1_440) {
        self.meetingTitle   = meetingTitle
        self.minutesUntil   = minutesUntil
        self.flightDuration = flightDuration
        self.screenWidth    = screenWidth
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
        // Measure the actual rendered content width so start/end offsets are exact
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: ContentWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(ContentWidthKey.self) { contentWidth = $0 }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .offset(x: xOffset)
        .opacity(opacity)
        // onAppear fires before layout, so contentWidth is 0 at that point.
        // onChange(of: contentWidth) fires after the first layout pass when the
        // GeometryReader preference is delivered — guaranteeing a real width.
        .onChange(of: contentWidth) { _, width in
            guard width > 0, xOffset == 0 else { return }  // only start once
            xOffset = -width  // start fully off-left
            withAnimation(.linear(duration: flightDuration)) {
                xOffset = screenWidth + width  // end fully off-right
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

/// PreferenceKey used to bubble up the HStack's measured width from GeometryReader.
private struct ContentWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    AirplaneView(meetingTitle: "Weekly Standup", minutesUntil: 5, flightDuration: 14)
        .frame(width: 1000, height: 100)
        .background(Color.gray.opacity(0.2))
}
