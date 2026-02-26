import AppKit
import SwiftUI
import SwiftData

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    var modelContainer: ModelContainer?
    var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - this is a menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Set the app icon explicitly so it appears correctly in About and other system UI
        NSApp.applicationIconImage = AppLogo.image
    }

    func showSettings() {
        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let settingsView = SettingsView(hotkeyManager: hotkeyManager)
            .frame(minWidth: 480, idealWidth: 520, minHeight: 420, idealHeight: 500)

        if let container = modelContainer {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 500),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "BoboMind Settings"
            window.minSize = NSSize(width: 480, height: 420)
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(
                rootView: settingsView.modelContainer(container)
            )
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            settingsWindow = window
        }
    }
}
