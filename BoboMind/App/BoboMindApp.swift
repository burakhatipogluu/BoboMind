import SwiftUI
import SwiftData

@main
struct BoboMindApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @State private var hotkeyManager: HotkeyManager?

    init() {
        UserDefaults.standard.register(defaults: [
            Constants.UserDefaultsKeys.historyLimit: Constants.defaultHistoryLimit,
            Constants.UserDefaultsKeys.showPreviewPanel: true,
            Constants.UserDefaultsKeys.enableCopySound: true,
            Constants.UserDefaultsKeys.excludePasswordManagers: true,
            Constants.UserDefaultsKeys.menuBarItemCount: 10,
        ])
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: BoboMindMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            logger.error("Could not create ModelContainer: \(error.localizedDescription)")
            // Attempt recovery by backing up corrupted store
            let storeURL = config.url
            let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let backupURL = storeURL.deletingPathExtension().appendingPathExtension("backup-\(timestamp).store")
            try? FileManager.default.moveItem(at: storeURL, to: backupURL)
            // Also move WAL/SHM if present
            for ext in ["-wal", "-shm"] {
                let src = URL(fileURLWithPath: storeURL.path + ext)
                let dst = URL(fileURLWithPath: backupURL.path + ext)
                try? FileManager.default.moveItem(at: src, to: dst)
            }
            // Show alert after launch
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Database Recovery"
                alert.informativeText = "The clipboard database was corrupted and has been backed up to:\n\(backupURL.lastPathComponent)\n\nA fresh database has been created."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            do {
                return try ModelContainer(
                    for: schema,
                    migrationPlan: BoboMindMigrationPlan.self,
                    configurations: [config]
                )
            } catch {
                fatalError("Could not create ModelContainer after recovery: \(error)")
            }
        }
    }()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(
                appState: appState,
                appDelegate: appDelegate
            )
            .modelContainer(sharedModelContainer)
            .onAppear {
                setupIfNeeded()
            }
        } label: {
            Image(systemName: "pawprint.fill")
        }
    }

    private func setupIfNeeded() {
        guard hotkeyManager == nil else { return }
        appDelegate.modelContainer = sharedModelContainer
        appState.modelContainer = sharedModelContainer
        appState.setup(modelContainer: sharedModelContainer)
        let hk = HotkeyManager(appState: appState)
        hotkeyManager = hk
        appState.hotkeyManager = hk
        appDelegate.hotkeyManager = hk
    }
}

// MARK: - Menu Bar Content

struct MenuBarContentView: View {
    let appState: AppState
    let appDelegate: AppDelegate

    @AppStorage(Constants.UserDefaultsKeys.menuBarItemCount) private var menuBarItemCount = 10
    @Query(sort: \ClipboardItem.lastUsedAt, order: .reverse)
    private var recentItems: [ClipboardItem]

    private var displayItems: [ClipboardItem] {
        Array(recentItems.prefix(menuBarItemCount))
    }

    var body: some View {
        Button("Show BoboMind History...") {
            appState.togglePanel()
        }
        .keyboardShortcut("v", modifiers: [.command, .shift])

        Divider()

        if displayItems.isEmpty {
            Text("No BoboMind history")
                .foregroundStyle(.secondary)
        } else {
            ForEach(displayItems) { item in
                Button {
                    appState.selectAndPaste(item)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.contentType.sfSymbol)
                            .frame(width: 16)

                        Text(item.title)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }

        Divider()

        Menu("Clear...") {
            Button("Clear All (Keep Pinned)") {
                appState.clearAll(keepPinned: true)
            }
            Button("Clear Everything") {
                appState.clearAll(keepPinned: false)
            }
        }

        Divider()

        Button("Settings...") {
            appDelegate.showSettings()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Quit BoboMind") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
