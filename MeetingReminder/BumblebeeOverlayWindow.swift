import AppKit
import SwiftUI

/// When the bumblebee cue arms. Independent of the airplane's Remind me picker.
enum BumblebeeCue {
    /// Minutes before the meeting the bee should appear.
    static let leadMinutes: Double = 3
    /// Half-width of the trigger window. Matches the airplane poller's slack
    /// so a 30-second check cannot skip the cue.
    static let windowSlack: Double = 1

    static func isInsideTriggerWindow(minutesUntil: Double) -> Bool {
        minutesUntil >= leadMinutes - windowSlack && minutesUntil <= leadMinutes + windowSlack
    }
}

/// Click-through sticker that hovers beside the pointer. Mouse events pass
/// through so the bee never blocks clicks or the flower.
final class BumblebeeCueWindow: NSPanel {
    static let beeSize: CGFloat = 78

    private let motion = BumblebeeMotion()
    private var timer: Timer?
    private var isTracking = false
    private var followStart = Date()
    private var lastMouse = NSEvent.mouseLocation

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.beeSize, height: Self.beeSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        motion.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        level = Self.overlayLevel
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isMovable = false
        canHide = false
        isFloatingPanel = true
        isExcludedFromWindowsMenu = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let host = NSHostingView(rootView: BumblebeeGlyphView(motion: motion))
        host.frame = NSRect(x: 0, y: 0, width: Self.beeSize, height: Self.beeSize)
        host.autoresizingMask = [.width, .height]
        host.wantsLayer = true
        host.layer?.backgroundColor = .clear
        contentView = host
        // Set after the hosting view so it cannot opt the window back into hit testing.
        ignoresMouseEvents = true
    }

    deinit {
        timer?.invalidate()
    }

    func startFollowingCursor() {
        followStart = Date()
        lastMouse = NSEvent.mouseLocation
        isTracking = true
        followCursor()

        timer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.followCursor()
        }
        timer.tolerance = 1.0 / 60.0
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stopFollowingCursor() {
        isTracking = false
        timer?.invalidate()
        timer = nil
    }

    private func followCursor() {
        guard isTracking else { return }
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main else { return }

        let reduce = motion.reduceMotion
        let t = Date().timeIntervalSince(followStart)
        let wobbleX: CGFloat = reduce ? 0 : CGFloat(sin(t * 2.3)) * 8
        let wobbleY: CGFloat = reduce ? 0 : CGFloat(sin(t * 3.4 + 0.8)) * 6

        // Sit up-left of the pointer so the arrow itself stays visible.
        var origin = NSPoint(
            x: mouse.x - Self.beeSize - 6 + wobbleX,
            y: mouse.y + 18 + wobbleY
        )
        let bounds = screen.visibleFrame
        if bounds.width > Self.beeSize, bounds.height > Self.beeSize {
            origin.x = min(max(origin.x, bounds.minX + 4), bounds.maxX - Self.beeSize - 4)
            origin.y = min(max(origin.y, bounds.minY + 4), bounds.maxY - Self.beeSize - 4)
        }
        setFrameOrigin(origin)

        let dx = mouse.x - lastMouse.x
        if abs(dx) > 1.2 {
            let facingRight = dx > 0
            if motion.facingRight != facingRight {
                motion.facingRight = facingRight
            }
        }
        lastMouse = mouse
    }

    fileprivate static var overlayLevel: NSWindow.Level {
        NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 1)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Small sticker in the bottom corner. Non-activating, so the click does not
/// bring MeetingReminder forward. It becomes key only for the click that
/// dismisses it; Acknowledge reminder in the menu is the keyboard path.
final class FlowerAckWindow: NSPanel {
    static let windowSize = NSSize(width: 184, height: 136)

    private let onAcknowledge: () -> Void
    private var didAcknowledge = false

    init(meetingTitle: String, screen: NSScreen, onAcknowledge: @escaping () -> Void) {
        self.onAcknowledge = onAcknowledge
        let size = Self.windowSize
        let visible = screen.visibleFrame
        let margin: CGFloat = 16
        let isRTL = NSApp.userInterfaceLayoutDirection == .rightToLeft
        let x = isRTL ? visible.minX + margin : visible.maxX - size.width - margin
        let y = visible.minY + margin

        super.init(
            contentRect: NSRect(origin: NSPoint(x: x, y: y), size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = NSWindow.Level(rawValue: Self.overlayLevel.rawValue + 1)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        hidesOnDeactivate = false
        isMovable = false
        isMovableByWindowBackground = false
        canHide = false
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        isExcludedFromWindowsMenu = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        title = "Acknowledge meeting reminder"

        let bounds = NSRect(origin: .zero, size: size)
        let host = NSHostingView(rootView: FlowerAckLabel(meetingTitle: meetingTitle))
        host.frame = bounds
        host.autoresizingMask = [.width, .height]
        host.wantsLayer = true
        host.layer?.backgroundColor = .clear
        host.isAccessibilityElement = false

        let click = AckClickView(frame: bounds)
        click.autoresizingMask = [.width, .height]
        click.toolTip = "Acknowledge \(meetingTitle)"
        click.onAcknowledge = { [weak self] in
            self?.acknowledgeIfNeeded()
        }
        click.isAccessibilityElement = true
        click.accessibilityRole = NSAccessibility.Role.button
        click.accessibilityLabel = "Acknowledge meeting reminder for \(meetingTitle)"
        click.accessibilityHelp = "Stops the bumblebee cue for this meeting"

        let container = NSView(frame: bounds)
        container.wantsLayer = true
        container.layer?.backgroundColor = .clear
        container.addSubview(host)
        container.addSubview(click)
        container.isAccessibilityElement = false
        container.accessibilityElements = [click]
        contentView = container
        ignoresMouseEvents = false
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            acknowledgeIfNeeded()
            return
        }
        super.sendEvent(event)
    }

    fileprivate func acknowledgeIfNeeded() {
        guard !didAcknowledge else { return }
        didAcknowledge = true
        let action = onAcknowledge
        // Leave sendEvent before tearing the panel down.
        DispatchQueue.main.async {
            action()
        }
    }

    // Must be able to become key or the click never arrives. The panel is
    // non-activating and only ordered front, so it does not take focus until
    // that dismissing click.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    fileprivate static var overlayLevel: NSWindow.Level {
        BumblebeeCueWindow.overlayLevel
    }
}

/// Transparent hit target over the flower sticker. Pointing-hand cursor and
/// VoiceOver press. The window's sendEvent handles the mouse click.
final class AckClickView: NSView {
    var onAcknowledge: (() -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var acceptsFirstResponder: Bool { false }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func accessibilityPerformPress() -> Bool {
        onAcknowledge?()
        return true
    }
}
