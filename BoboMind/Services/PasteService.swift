import AppKit

@MainActor
final class PasteService {
    private let pasteboard = NSPasteboard.general
    /// Reference to clipboard monitor so we can suppress capture during paste.
    weak var clipboardMonitor: ClipboardMonitor?
    /// Change count recorded after our own write; monitor uses this to skip our pastes.
    private(set) var lastPasteChangeCount: Int = -1

    /// Writes the clip contents to the system pasteboard.
    func copyToPasteboard(item: ClipboardItem, plainTextOnly: Bool = false) {
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

        lastPasteChangeCount = pasteboard.changeCount
    }

    /// Writes plain text (e.g. a snippet) to the pasteboard with proper monitor suppression.
    func copySnippetToPasteboard(text: String) {
        pasteboard.clearContents()
        pasteboard.setData(Data(), forType: ClipboardMonitor.selfPasteType)
        pasteboard.setString(text, forType: .string)

        lastPasteChangeCount = pasteboard.changeCount
    }
}
