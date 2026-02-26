import AppKit
import SwiftUI
import SwiftData

enum SnippetEditorWindow {
    private static var window: NSWindow?
    private static var currentDelegate: WindowCloseDelegate?

    static func show(snippet: Snippet?, modelContext: ModelContext, onDismiss: @escaping () -> Void) {
        close()

        let editorView = SnippetEditorView(snippet: snippet, onDismiss: {
            close()
            onDismiss()
        })
        .environment(\.modelContext, modelContext)

        let hostingView = NSHostingView(rootView: editorView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 340)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 340),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.contentView = hostingView
        win.title = snippet == nil ? "New Snippet" : "Edit Snippet"
        win.titlebarAppearsTransparent = true
        win.isMovableByWindowBackground = true
        win.center()
        win.level = .floating + 1
        win.isReleasedWhenClosed = false

        let delegate = WindowCloseDelegate()
        delegate.onClose = {
            onDismiss()
            self.window = nil
            self.currentDelegate = nil
        }
        win.delegate = delegate
        currentDelegate = delegate

        window = win
        win.makeKeyAndOrderFront(nil)
    }

    static func close() {
        window?.close()
        window = nil
        currentDelegate = nil
    }
}

private final class WindowCloseDelegate: NSObject, NSWindowDelegate {
    var onClose: (() -> Void)?

    func windowWillClose(_ notification: Notification) {
        onClose?()
        onClose = nil
    }
}
