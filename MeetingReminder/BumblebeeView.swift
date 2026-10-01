import Combine
import SwiftUI

/// Flat sticker colors sampled from the airplane and banner artwork.
enum StickerPalette {
    static let pink = Color(red: 219 / 255, green: 133 / 255, blue: 179 / 255)
    static let blush = Color(red: 248 / 255, green: 215 / 255, blue: 1)
    static let honey = Color(red: 245 / 255, green: 196 / 255, blue: 49 / 255)
    static let ink = Color.black
}

/// Cursor-follow facing and Reduce Motion, owned by the bee window.
final class BumblebeeMotion: ObservableObject {
    @Published var facingRight: Bool = true
    @Published var reduceMotion: Bool = false
}

/// Little bumblebee sticker. Wings flap unless Reduce Motion is on.
struct BumblebeeGlyphView: View {
    @ObservedObject var motion: BumblebeeMotion
    @State private var wingsUp = false

    var body: some View {
        BumblebeeGlyph(wingsUp: wingsUp, facingRight: motion.facingRight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
            .onAppear {
                guard !motion.reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.32).repeatForever(autoreverses: true)) {
                    wingsUp = true
                }
            }
            .onChange(of: motion.reduceMotion) { _, reduce in
                if reduce { wingsUp = false }
            }
    }
}

struct BumblebeeGlyph: View {
    var wingsUp: Bool
    var facingRight: Bool

    var body: some View {
        ZStack {
            wing(width: 28, height: 16)
                .rotationEffect(.degrees(wingsUp ? -30 : 6), anchor: .bottom)
                .offset(x: -2, y: -9)
            wing(width: 20, height: 12)
                .rotationEffect(.degrees(wingsUp ? -46 : -4), anchor: .bottom)
                .offset(x: 7, y: -7)

            abdomen
            head
            antenna
        }
        .scaleEffect(x: facingRight ? 1 : -1, y: 1)
        .frame(width: 72, height: 72)
    }

    private var abdomen: some View {
        Capsule()
            .fill(StickerPalette.honey)
            .frame(width: 34, height: 20)
            .overlay {
                HStack(spacing: 4) {
                    stripe
                    stripe
                    stripe
                }
            }
            .clipShape(Capsule())
            .overlay {
                Capsule().strokeBorder(StickerPalette.ink, lineWidth: 2.5)
            }
            .offset(x: -6, y: 2)
    }

    private var stripe: some View {
        Rectangle()
            .fill(StickerPalette.ink)
            .frame(width: 3.5, height: 22)
    }

    private var head: some View {
        ZStack {
            Circle().fill(StickerPalette.ink)
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .offset(x: 2.5, y: -1.5)
            Circle()
                .fill(StickerPalette.ink)
                .frame(width: 2.5, height: 2.5)
                .offset(x: 3.2, y: -1.5)
        }
        .frame(width: 16, height: 16)
        .offset(x: 14, y: 1)
    }

    private var antenna: some View {
        ZStack {
            Capsule()
                .fill(StickerPalette.ink)
                .frame(width: 2, height: 10)
                .rotationEffect(.degrees(-28))
            Circle()
                .fill(StickerPalette.ink)
                .frame(width: 4, height: 4)
                .offset(x: 4, y: -5)
        }
        .offset(x: 18, y: -12)
    }

    private func wing(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(StickerPalette.blush.opacity(0.92))
            Ellipse().strokeBorder(StickerPalette.ink, lineWidth: 2)
        }
        .frame(width: width, height: height)
    }
}

/// Corner sticker the user presses to acknowledge the cue.
struct FlowerAckLabel: View {
    let meetingTitle: String

    var body: some View {
        VStack(spacing: 1) {
            FlowerGlyph()
                .frame(width: 42, height: 42)
            Text("got it")
                .font(.custom("Comic Sans MS", size: 16))
                .foregroundStyle(StickerPalette.ink)
            Text(meetingTitle)
                .font(.custom("Comic Sans MS", size: 11))
                .foregroundStyle(StickerPalette.ink.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(StickerPalette.pink)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(StickerPalette.ink, lineWidth: 3)
        }
        .padding(8)
        .accessibilityHidden(true)
    }
}

struct FlowerGlyph: View {
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                ZStack {
                    Ellipse().fill(StickerPalette.blush)
                    Ellipse().strokeBorder(StickerPalette.ink, lineWidth: 2)
                }
                .frame(width: 14, height: 20)
                .offset(y: -10)
                .rotationEffect(.degrees(Double(index) * 72))
            }
            ZStack {
                Circle().fill(StickerPalette.honey)
                Circle().strokeBorder(StickerPalette.ink, lineWidth: 2)
            }
            .frame(width: 14, height: 14)
        }
    }
}

#Preview("Bee") {
    BumblebeeGlyphView(motion: BumblebeeMotion())
        .frame(width: 78, height: 78)
        .background(Color.gray.opacity(0.25))
}

#Preview("Flower") {
    FlowerAckLabel(meetingTitle: "Weekly Standup")
        .frame(width: 184, height: 132)
        .background(Color.gray.opacity(0.3))
}
