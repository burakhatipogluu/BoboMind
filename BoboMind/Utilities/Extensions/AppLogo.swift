import AppKit

enum AppLogo {
    static var image: NSImage {
        // 1. Try Bundle.main (xcodebuild .app bundle)
        if let url = Bundle.main.url(forResource: "AppLogo", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        // 2. Try SPM resource bundle next to the binary
        let execURL = Bundle.main.executableURL ?? Bundle.main.bundleURL
        let spmBundleURL = execURL
            .deletingLastPathComponent()
            .appendingPathComponent("BoboMind_BoboMind.bundle")
        if let spmBundle = Bundle(url: spmBundleURL),
           let url = spmBundle.url(forResource: "AppLogo", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        // 3. Try AppIcon from asset catalog
        if let icon = NSImage(named: "AppIcon") {
            return icon
        }
        // 4. Fallback to system app icon
        return NSApp.applicationIconImage
    }
}
