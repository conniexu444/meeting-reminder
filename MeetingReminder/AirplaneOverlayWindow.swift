import AppKit
import SwiftUI

// Transparent, click-through panel that floats above every window (including fullscreen apps).
final class AirplaneOverlayWindow: NSPanel {

    init(meetingTitle: String, minutesUntil: Int, flightDuration: Double) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let sf = screen.frame
        let height: CGFloat = 110
        // Position ~65% up the screen
        let yPos = sf.minY + sf.height * 0.65

        super.init(
            contentRect: NSRect(x: sf.minX, y: yPos, width: sf.width, height: height),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )

        // Float above everything, including fullscreen spaces
        self.level               = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 1)
        self.backgroundColor     = .clear
        self.isOpaque            = false
        self.hasShadow           = false
        self.ignoresMouseEvents  = true
        self.collectionBehavior  = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isReleasedWhenClosed = false

        let rootView     = AirplaneView(meetingTitle: meetingTitle,
                                        minutesUntil:  minutesUntil,
                                        flightDuration: flightDuration)
        let hostingView  = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(x: 0, y: 0, width: sf.width, height: height)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        self.contentView = hostingView
    }

    override var canBecomeKey:  Bool { false }
    override var canBecomeMain: Bool { false }
}
