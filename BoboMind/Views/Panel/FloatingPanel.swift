import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    private var closeOnEscape = true
    var onClose: (() -> Void)?
    private var clickMonitor: Any?

    init(contentView: NSView, width: CGFloat = 620, height: CGFloat = 480, position: PopupPosition = .center) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovableByWindowBackground = true

        level = .floating
        isFloatingPanel = true
        // Don't use hidesOnDeactivate — menu bar apps are never "active"
        // in the normal sense, causing the panel to hide immediately.
        hidesOnDeactivate = false

        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        animationBehavior = .utilityWindow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        // Visual effect background for vibrancy
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true

        visualEffect.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])

        self.contentView = visualEffect

        positionPanel(position)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func resignKey() {
        super.resignKey()
        // Delay close slightly to allow context menus and other key-stealing
        // interactions to complete. Without this, right-clicking a clip to open
        // a context menu would dismiss the panel immediately.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self, self.isVisible, !self.isKeyWindow else { return }
            self.animateOut()
        }
    }

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
        // Guard against double-close (e.g. resignKey + Escape at the same time)
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

        // Clamp to screen bounds
        origin.x = max(screenFrame.minX, min(origin.x, screenFrame.maxX - panelSize.width))
        origin.y = max(screenFrame.minY, min(origin.y, screenFrame.maxY - panelSize.height))

        setFrameOrigin(origin)
    }
}
