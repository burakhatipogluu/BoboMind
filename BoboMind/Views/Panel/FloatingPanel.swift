import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    private var closeOnEscape = true
    var onClose: (() -> Void)?

    init(contentView: NSView, width: CGFloat = 620, height: CGFloat = 480, position: PopupPosition = .center) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        titlebarSeparatorStyle = .none
        isMovableByWindowBackground = true

        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false

        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        animationBehavior = .utilityWindow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        minSize = NSSize(width: width, height: height)
        maxSize = NSSize(width: width, height: height)
        setContentSize(NSSize(width: width, height: height))

        // NSPanel + NSHostingView can enter a constraints feedback loop if the window
        // uses titlebar layout guides while SwiftUI keeps invalidating intrinsic size.
        // Using fullSizeContentView plus an explicit container keeps geometry one-way:
        // window size -> container bounds -> hosting view frame.
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        container.wantsLayer = true
        container.layer?.cornerRadius = 12
        container.layer?.masksToBounds = true

        contentView.translatesAutoresizingMaskIntoConstraints = true
        contentView.autoresizingMask = [.width, .height]
        contentView.frame = container.bounds
        container.addSubview(contentView)

        self.contentView = container

        positionPanel(position)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func resignKey() {
        super.resignKey()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self, self.isVisible, !self.isKeyWindow else { return }
            // Don't dismiss if the frontmost app is a screenshot/screen capture tool
            if let frontApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
               Self.screenshotBundleIDs.contains(frontApp) {
                return
            }
            self.animateOut()
        }
    }

    private static let screenshotBundleIDs: Set<String> = [
        "com.apple.screencaptureui",       // macOS Screenshot (⌘⇧5)
        "com.apple.Screenshot",            // macOS Screenshot
        "com.apple.screencapture",         // Screen Capture
        "com.apple.preview",               // Preview (screenshot from menu)
        "com.shottr.shottr",               // Shottr
        "com.cleanshot.app",               // CleanShot X
        "cc.snappy.Snappy",               // Snappy
        "org.skitch.skitch",              // Skitch
        "com.monosnap.monosnap",          // Monosnap
    ]

    override func cancelOperation(_ sender: Any?) {
        if closeOnEscape {
            animateOut()
        }
    }

    func animateIn() {
        alphaValue = 0
        makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1
        }
    }

    func animateOut() {
        guard isVisible else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.close()
            self?.onClose?()
            self?.onClose = nil
        })
    }

    private func positionPanel(_ position: PopupPosition) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = frame.size
        let margin: CGFloat = 20

        var origin: NSPoint

        switch position {
        case .center:
            origin = NSPoint(
                x: screenFrame.midX - panelSize.width / 2,
                y: screenFrame.midY - panelSize.height / 2 + screenFrame.height * 0.1
            )
        case .mouseCursor:
            let mouseLocation = NSEvent.mouseLocation
            origin = NSPoint(
                x: mouseLocation.x - panelSize.width / 2,
                y: mouseLocation.y - panelSize.height
            )
        case .topCenter:
            origin = NSPoint(
                x: screenFrame.midX - panelSize.width / 2,
                y: screenFrame.maxY - panelSize.height - margin
            )
        case .bottomCenter:
            origin = NSPoint(
                x: screenFrame.midX - panelSize.width / 2,
                y: screenFrame.minY + margin
            )
        case .leftCenter:
            origin = NSPoint(
                x: screenFrame.minX + margin,
                y: screenFrame.midY - panelSize.height / 2
            )
        case .rightCenter:
            origin = NSPoint(
                x: screenFrame.maxX - panelSize.width - margin,
                y: screenFrame.midY - panelSize.height / 2
            )
        }

        origin.x = max(screenFrame.minX, min(origin.x, screenFrame.maxX - panelSize.width))
        origin.y = max(screenFrame.minY, min(origin.y, screenFrame.maxY - panelSize.height))

        setFrameOrigin(origin)
    }
}
