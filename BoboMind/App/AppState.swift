import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppState {
    let clipboardMonitor = ClipboardMonitor()
    let pasteService = PasteService()
    var storageService: StorageService?
    var hotkeyManager: HotkeyManager?

    var searchText = ""
    var filterType: ContentType?

    enum SidebarFilter: Equatable {
        case all
        case pinned
        case snippets
        case group(PersistentIdentifier)
    }
    var sidebarFilter: SidebarFilter = .all

    var panel: FloatingPanel?
    var modelContainer: ModelContainer?

    func setup(modelContainer: ModelContainer) {
        let service = StorageService(modelContainer: modelContainer)
        self.storageService = service
        pasteService.clipboardMonitor = clipboardMonitor
        clipboardMonitor.pasteService = pasteService

        // Seed sample snippets on first launch
        seedSampleSnippetsIfNeeded(modelContainer: modelContainer)

        clipboardMonitor.onNewClip = { [weak self] hash, title, plainText, contentType, contents, bundleID, appName in
            guard let self, let storage = self.storageService else { return }
            // Read UserDefaults on MainActor before crossing into actor
            // 0 = unlimited, positive = actual limit
            let effectiveLimit = UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.historyLimit)
            Task {
                do {
                    try await storage.saveClip(
                        hash: hash,
                        title: title,
                        plainText: plainText,
                        contentType: contentType,
                        contents: contents,
                        sourceAppBundleID: bundleID,
                        sourceAppName: appName,
                        historyLimit: effectiveLimit
                    )
                } catch {
                    logger.error("Failed to save clip: \(error.localizedDescription)")
                }
            }
        }

        clipboardMonitor.start()
    }

    func selectAndPaste(_ item: ClipboardItem, plainTextOnly: Bool = false) {
        pasteService.copyToPasteboard(item: item, plainTextOnly: plainTextOnly)

        if UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.enableCopySound) {
            Self.playPasteSound()
        }

        if let storage = storageService {
            Task {
                do {
                    try await storage.markUsed(item.persistentModelID)
                } catch {
                    logger.error("Failed to mark used: \(error.localizedDescription)")
                }
            }
        }
    }

    func togglePin(_ item: ClipboardItem) {
        if let storage = storageService {
            Task {
                do {
                    try await storage.togglePin(item.persistentModelID)
                } catch {
                    logger.error("Failed to toggle pin: \(error.localizedDescription)")
                }
            }
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        if let storage = storageService {
            Task {
                do {
                    try await storage.deleteClip(item.persistentModelID)
                } catch {
                    logger.error("Failed to delete clip: \(error.localizedDescription)")
                }
            }
        }
    }

    func clearAll(keepPinned: Bool = true) {
        if let storage = storageService {
            Task {
                do {
                    try await storage.clearAll(keepPinned: keepPinned)
                } catch {
                    logger.error("Failed to clear all: \(error.localizedDescription)")
                }
            }
        }
    }

    func togglePanel() {
        if let existing = panel, existing.isVisible {
            existing.animateOut()
            return
        }
        openNewPanel()
    }

    private static func playPasteSound() {
        NSSound(named: "Blow")?.play()
    }

    private func openNewPanel() {
        guard let modelContainer else { return }

        searchText = ""
        filterType = nil
        sidebarFilter = .all

        let positionRaw = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.popupPosition) ?? ""
        let position = PopupPosition(rawValue: positionRaw) ?? .center

        let sizeRaw = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.panelSize) ?? ""
        let panelSize = PanelSize(rawValue: sizeRaw) ?? .standard

        let mainView = MainView()
            .environment(self)
            .modelContainer(modelContainer)

        let hostingView = NSHostingView(rootView: mainView)
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.autoresizingMask = [.width, .height]

        let newPanel = FloatingPanel(contentView: hostingView, width: panelSize.width, height: panelSize.height, position: position)
        newPanel.onClose = { [weak self] in
            self?.panel = nil
        }
        newPanel.animateIn()
        panel = newPanel
    }

    // MARK: - Seed Data

    private func seedSampleSnippetsIfNeeded(modelContainer: ModelContainer) {
        let key = "hasSeededSampleSnippets"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let context = ModelContext(modelContainer)
        let samples: [(String, String, String)] = [
            ("Email Signature", "Best regards,\nBurak Hatipoğlu\nSenior DBA", "sig"),
            ("Meeting Note Template", "## Meeting: [Title]\n**Date:** \n**Attendees:** \n\n### Agenda\n- \n\n### Action Items\n- [ ] \n", "meeting"),
            ("Code Review Comment", "Great work overall! A few suggestions:\n\n1. Consider extracting this logic into a separate method\n2. Add error handling for edge cases\n3. Unit tests would be helpful here", "review"),
            ("Quick Reply — Acknowledged", "Thanks for the update! I'll review this and get back to you shortly.", "ack"),
            ("Terminal — Git Status", "git status && git log --oneline -10", "gs"),
            ("SQL — Active Sessions", "SELECT sid, serial#, username, status, machine\nFROM v$session\nWHERE status = 'ACTIVE'\nORDER BY last_call_et DESC;", "orasql"),
        ]

        for (title, content, keyword) in samples {
            let snippet = Snippet(title: title, content: content, keyword: keyword)
            context.insert(snippet)
        }
        try? context.save()
    }
}
