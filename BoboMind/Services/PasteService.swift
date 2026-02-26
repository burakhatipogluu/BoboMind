import AppKit

@MainActor
final class PasteService {
    private let pasteboard = NSPasteboard.general
    /// Reference to clipboard monitor so we can suppress capture during paste.
    weak var clipboardMonitor: ClipboardMonitor?

    /// Writes the clip contents to the system pasteboard.
    /// In sandbox mode, the user manually pastes with Cmd+V.
    func copyToPasteboard(item: ClipboardItem, plainTextOnly: Bool = false) {
        // Suppress monitor during pasteboard writes to avoid race condition.
        // Keep isPasting true longer than the synchronous write so the next
        // timer poll (up to 0.5 s later) still sees the flag.
        clipboardMonitor?.isPasting = true

        pasteboard.clearContents()

        // Mark as internal paste so ClipboardMonitor ignores it
        pasteboard.setData(Data(), forType: ClipboardMonitor.selfPasteType)

        if plainTextOnly, let text = item.plainText {
            pasteboard.setString(text, forType: .string)
        } else {
            for content in item.contents {
                let type = NSPasteboard.PasteboardType(content.pasteboardType)
                pasteboard.setData(content.data, forType: type)
            }
        }

        // Reset after a delay that exceeds the polling interval
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.clipboardMonitor?.isPasting = false
        }
    }

    /// Writes plain text (e.g. a snippet) to the pasteboard with proper monitor suppression.
    func copySnippetToPasteboard(text: String) {
        clipboardMonitor?.isPasting = true

        pasteboard.clearContents()
        pasteboard.setData(Data(), forType: ClipboardMonitor.selfPasteType)
        pasteboard.setString(text, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.clipboardMonitor?.isPasting = false
        }
    }
}
