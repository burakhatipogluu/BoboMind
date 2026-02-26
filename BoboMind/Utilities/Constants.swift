import Foundation
import os

let logger = Logger(subsystem: "com.bobomind.app", category: "general")

enum Constants {
    static let defaultPollingInterval: TimeInterval = 0.5
    static let defaultHistoryLimit: Int = 500
    static let maxTitleLength: Int = 200
    static let selfPasteUTI = "com.bobomind.self-paste"

    enum UserDefaultsKeys {
        static let historyLimit = "historyLimit"
        static let launchAtLogin = "launchAtLogin"
        static let showPreviewPanel = "showPreviewPanel"
        static let excludedApps = "excludedApps"
        static let popupPosition = "popupPosition"
        static let enableCopySound = "enableCopySound"
        static let excludePasswordManagers = "excludePasswordManagers"
        static let menuBarItemCount = "menuBarItemCount"
        static let panelSize = "panelSize"
    }

    static let passwordManagerBundleIDs: Set<String> = [
        "com.1password.1password",           // 1Password
        "com.agilebits.onepassword7",        // 1Password 7
        "com.bitwarden.desktop",             // Bitwarden
        "com.lastpass.LastPass",             // LastPass
        "com.dashlane.Dashlane",             // Dashlane
        "org.keepassxc.keepassxc",           // KeePassXC
        "in.sinew.Enpass-Desktop",           // Enpass
        "com.nordpass.macos.NordPass",       // NordPass
        "com.apple.Passwords",              // Apple Passwords
    ]
}
