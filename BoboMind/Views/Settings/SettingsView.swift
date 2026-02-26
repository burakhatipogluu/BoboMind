import SwiftUI
import SwiftData
import ServiceManagement

struct SettingsView: View {
    var hotkeyManager: HotkeyManager?
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            HotkeySettingsView(hotkeyManager: hotkeyManager)
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(Constants.UserDefaultsKeys.historyLimit) private var historyLimit = Constants.defaultHistoryLimit
    @AppStorage(Constants.UserDefaultsKeys.menuBarItemCount) private var menuBarItemCount = 10
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @AppStorage(Constants.UserDefaultsKeys.excludePasswordManagers) private var excludePasswordManagers = true

    @Query private var allClips: [ClipboardItem]
    @Query private var allSnippets: [Snippet]

    @State private var toast: ToastItem?
    @State private var isToastVisible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Startup
                SettingsSection(title: "Startup", icon: "power") {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                launchAtLogin = !newValue
                            }
                        }
                }

                // History
                SettingsSection(title: "History", icon: "clock.arrow.circlepath") {
                    LabeledContent("Keep last") {
                        Picker("", selection: $historyLimit) {
                            Text("100 clips").tag(100)
                            Text("500 clips").tag(500)
                            Text("1,000 clips").tag(1000)
                            Text("5,000 clips").tag(5000)
                            Text("Unlimited").tag(0)
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }

                    LabeledContent("Menu bar items") {
                        Picker("", selection: $menuBarItemCount) {
                            Text("5").tag(5)
                            Text("10").tag(10)
                            Text("15").tag(15)
                            Text("20").tag(20)
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }
                }

                // Data
                SettingsSection(title: "Data", icon: "externaldrive") {
                    HStack(spacing: 10) {
                        Button("Export...") {
                            Task {
                                if let result = await ExportImportService.showExportPanel(
                                    clips: allClips, snippets: allSnippets
                                ) {
                                    presentToast(result)
                                }
                            }
                        }
                        Button("Import...") {
                            Task {
                                if let result = await ExportImportService.showImportPanel(
                                    modelContext: modelContext, modelContainer: modelContext.container
                                ) {
                                    presentToast(result)
                                }
                            }
                        }
                    }
                    Text("Export clips and snippets as JSON. Only text-based clips can be imported.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                // Privacy
                SettingsSection(title: "Privacy", icon: "lock.shield") {
                    Toggle("Exclude password managers", isOn: $excludePasswordManagers)
                    Text("Ignores copies from 1Password, Bitwarden, LastPass, Dashlane, KeePassXC, Enpass, NordPass, Apple Passwords, and their browser extensions.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    ExcludedAppsView()
                }
            }
            .padding(24)
        }
        .overlay(alignment: .top) {
            if isToastVisible, let toast {
                ToastView(item: toast)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func presentToast(_ result: ExportImportResult) {
        toast = ToastItem(
            isSuccess: result.success,
            title: result.success ? "Success" : "Failed",
            detail: result.message
        )
        withAnimation(.easeOut(duration: 0.25)) {
            isToastVisible = true
        }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut(duration: 0.25)) {
                isToastVisible = false
            }
        }
    }
}

// MARK: - Shortcuts

struct HotkeySettingsView: View {
    var hotkeyManager: HotkeyManager?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection(title: "Global Shortcut", icon: "globe") {
                    ShortcutRecorderView(
                        label: "Show BoboMind:",
                        shortcut: hotkeyManager?.currentShortcut ?? HotkeyManager.defaultShortcut,
                        onChange: { shortcut in
                            hotkeyManager?.updateShortcut(shortcut)
                        }
                    )

                    HStack {
                        Spacer()
                        Button("Reset to Default (⌘⇧V)") {
                            hotkeyManager?.resetToDefault()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                    }
                }

                SettingsSection(title: "Panel Shortcuts", icon: "command") {
                    VStack(alignment: .leading, spacing: 8) {
                        shortcutRow("Return", "Paste selected clip")
                        shortcutRow("Shift + Return", "Paste as plain text")
                        shortcutRow("Up / Down Arrow", "Navigate clips")
                        shortcutRow("Cmd + P", "Pin / Unpin clip")
                        shortcutRow("Delete", "Delete selected clip")
                        shortcutRow("Escape", "Close panel")
                    }
                }
            }
            .padding(24)
        }
    }

    private func shortcutRow(_ key: String, _ description: String) -> some View {
        HStack {
            Text(key)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.quaternary)
                )
            Spacer()
            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Appearance

struct AppearanceSettingsView: View {
    @AppStorage(Constants.UserDefaultsKeys.showPreviewPanel) private var showPreview = true
    @AppStorage(Constants.UserDefaultsKeys.popupPosition) private var popupPosition: PopupPosition = .center
    @AppStorage(Constants.UserDefaultsKeys.panelSize) private var panelSize: PanelSize = .standard
    @AppStorage(Constants.UserDefaultsKeys.enableCopySound) private var enableCopySound = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection(title: "Panel", icon: "macwindow") {
                    LabeledContent("Popup position") {
                        Picker("", selection: $popupPosition) {
                            ForEach(PopupPosition.allCases) { position in
                                Text(position.displayName).tag(position)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }

                    LabeledContent("Panel size") {
                        Picker("", selection: $panelSize) {
                            ForEach(PanelSize.allCases) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }

                    Toggle("Show preview panel", isOn: $showPreview)
                }

                SettingsSection(title: "Sound", icon: "speaker.wave.2") {
                    Toggle("Play sound when pasting from history", isOn: $enableCopySound)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Excluded Apps

struct ExcludedAppsView: View {
    @State private var excludedApps: [String] = []
    @State private var newBundleID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 4)

            Text("Excluded Apps")
                .font(.callout)
                .fontWeight(.medium)

            Text("BoboMind will ignore copies from these apps.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if !excludedApps.isEmpty {
                VStack(spacing: 4) {
                    ForEach(excludedApps, id: \.self) { app in
                        HStack {
                            Text(app)
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    excludedApps.removeAll { $0 == app }
                                    save()
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.quaternary.opacity(0.5))
                        )
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("com.example.app", text: $newBundleID)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.callout, design: .monospaced))

                Button("Add") {
                    let trimmed = newBundleID.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, !excludedApps.contains(trimmed) else { return }
                    withAnimation(.easeOut(duration: 0.15)) {
                        excludedApps.append(trimmed)
                    }
                    newBundleID = ""
                    save()
                }
                .disabled(newBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            excludedApps = UserDefaults.standard.stringArray(forKey: Constants.UserDefaultsKeys.excludedApps) ?? []
        }
    }

    private func save() {
        UserDefaults.standard.set(excludedApps, forKey: Constants.UserDefaultsKeys.excludedApps)
    }
}

// MARK: - About

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(nsImage: AppLogo.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

            VStack(spacing: 6) {
                Text("BoboMind")
                    .font(.system(.title, design: .rounded, weight: .bold))

                Text("Smart Clipboard Manager for macOS")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("Version \(appVersion)")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }

            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Button {
                        NSWorkspace.shared.open(URL(string: "https://github.com/burakhatipogluu/BoboMind")!)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                            Text("GitHub")
                        }
                        .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)

                    Button {
                        NSWorkspace.shared.open(URL(string: "https://github.com/burakhatipogluu/BoboMind/blob/main/PRIVACY.md")!)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.raised")
                            Text("Privacy Policy")
                        }
                        .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)

                    Button {
                        NSWorkspace.shared.open(URL(string: "https://github.com/burakhatipogluu/BoboMind/issues")!)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle")
                            Text("Support")
                        }
                        .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }

                Text("Made with ❤️ by Burak Hatipoğlu")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Privacy & Data
            VStack(spacing: 6) {
                Text("Privacy & Data")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text("BoboMind stores your clipboard history locally on your device only. No data is transmitted to any server. No analytics or tracking. You can delete all data at any time from Settings.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Reusable Section Component

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
        }
    }
}

