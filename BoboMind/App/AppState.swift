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
            .frame(width: panelSize.width, height: panelSize.height)

        let hostingView = NSHostingView(rootView: mainView)
        hostingView.layer?.backgroundColor = .clear
        let newPanel = FloatingPanel(contentView: hostingView, width: panelSize.width, height: panelSize.height, position: position)
        newPanel.onClose = { [weak self] in
            self?.panel = nil
        }
        newPanel.animateIn()
        panel = newPanel
    }
}
