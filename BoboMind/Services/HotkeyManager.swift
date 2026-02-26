import Carbon
import Cocoa
import Combine

// MARK: - Native Global Hotkey Manager

@MainActor
final class HotkeyManager {
    private weak var appState: AppState?
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var retainedSelf: Unmanaged<HotkeyManager>?
    
    /// The current shortcut stored as modifier flags + key code
    @Published var currentShortcut: HotkeyShortcut
    
    static let defaultShortcut = HotkeyShortcut(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey | shiftKey)
    )
    
    init(appState: AppState) {
        self.appState = appState
        
        // Load saved shortcut or use default (Cmd+Shift+V)
        if let data = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.globalHotkey),
           let shortcut = try? JSONDecoder().decode(HotkeyShortcut.self, from: data) {
            self.currentShortcut = shortcut
        } else {
            self.currentShortcut = Self.defaultShortcut
        }
        
        registerHotkey()
    }
    
    deinit {
        // Note: cleanup() must be called explicitly before deinit since it's @MainActor
    }
    
    func cleanup() {
        unregisterHotkey()
        retainedSelf?.release()
        retainedSelf = nil
    }
    
    func updateShortcut(_ shortcut: HotkeyShortcut) {
        currentShortcut = shortcut
        if let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: Constants.UserDefaultsKeys.globalHotkey)
        }
        unregisterHotkey()
        registerHotkey()
    }
    
    func resetToDefault() {
        updateShortcut(Self.defaultShortcut)
    }
    
    // MARK: - Carbon Hotkey Registration
    
    private func registerHotkey() {
        let hotkeyID = EventHotKeyID(signature: OSType(0x424D4430), id: 1) // "BMD0"
        
        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handlerBlock: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            Task { @MainActor in
                manager.appState?.togglePanel()
            }
            return noErr
        }
        
        let retained = Unmanaged.passRetained(self)
        retainedSelf = retained
        let refcon = retained.toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), handlerBlock, 1, &eventType, refcon, &eventHandler)
        
        RegisterEventHotKey(
            currentShortcut.keyCode,
            currentShortcut.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
    }
    
    private func unregisterHotkey() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}

// MARK: - Shortcut Model

struct HotkeyShortcut: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    
    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        parts.append(Self.keyCodeToString(keyCode))
        return parts.joined()
    }
    
    static func keyCodeToString(_ keyCode: UInt32) -> String {
        let keyMap: [UInt32: String] = [
            UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
            UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
            UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
            UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
            UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
            UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
            UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
            UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
            UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
            UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
            UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
            UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
            UInt32(kVK_ANSI_9): "9",
            UInt32(kVK_Space): "Space", UInt32(kVK_Return): "Return",
            UInt32(kVK_Tab): "Tab", UInt32(kVK_Escape): "Esc",
            UInt32(kVK_F1): "F1", UInt32(kVK_F2): "F2", UInt32(kVK_F3): "F3",
            UInt32(kVK_F4): "F4", UInt32(kVK_F5): "F5", UInt32(kVK_F6): "F6",
            UInt32(kVK_F7): "F7", UInt32(kVK_F8): "F8", UInt32(kVK_F9): "F9",
            UInt32(kVK_F10): "F10", UInt32(kVK_F11): "F11", UInt32(kVK_F12): "F12",
        ]
        return keyMap[keyCode] ?? "?"
    }
    
    /// Convert from NSEvent modifier flags to Carbon modifier mask
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }
}
