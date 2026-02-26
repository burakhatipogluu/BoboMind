import SwiftUI
import Carbon

/// A native shortcut recorder view that replaces KeyboardShortcuts.Recorder
struct ShortcutRecorderView: View {
    let label: String
    @ObservedObject private var recorder = ShortcutRecorderState()
    var onShortcutChange: ((HotkeyShortcut) -> Void)?
    
    @State private var currentDisplay: String
    
    init(label: String, shortcut: HotkeyShortcut, onChange: ((HotkeyShortcut) -> Void)? = nil) {
        self.label = label
        self.onShortcutChange = onChange
        self._currentDisplay = State(initialValue: shortcut.displayString)
    }
    
    var body: some View {
        HStack {
            Text(label)
            
            Spacer()
            
            Button(action: {
                recorder.isRecording.toggle()
            }) {
                Text(recorder.isRecording ? "Press shortcut..." : currentDisplay)
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(minWidth: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(recorder.isRecording ? Color.accentColor.opacity(0.15) : Color(.quaternarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(recorder.isRecording ? Color.accentColor : Color.clear, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .onAppear {
                recorder.onRecorded = { shortcut in
                    currentDisplay = shortcut.displayString
                    onShortcutChange?(shortcut)
                }
            }
        }
    }
}

// MARK: - Recorder State

@MainActor
final class ShortcutRecorderState: ObservableObject {
    @Published var isRecording = false {
        didSet {
            if isRecording {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }
    
    var onRecorded: ((HotkeyShortcut) -> Void)?
    private var monitor: Any?
    
    private func startMonitoring() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isRecording else { return event }
            
            // Escape cancels recording
            if event.keyCode == UInt16(kVK_Escape) {
                self.isRecording = false
                return nil
            }
            
            // Require at least one modifier
            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
            guard !flags.isEmpty else { return nil }
            
            let shortcut = HotkeyShortcut(
                keyCode: UInt32(event.keyCode),
                modifiers: HotkeyShortcut.carbonModifiers(from: flags)
            )
            
            self.isRecording = false
            self.onRecorded?(shortcut)
            return nil
        }
    }
    
    private func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
