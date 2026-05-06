#if os(macOS)
import AppKit
import Carbon
import SwiftUI

struct MacShortcutRecorder: View {
    @Binding var shortcut: MacQuickCaptureShortcut
    var onChange: (MacQuickCaptureShortcut) -> Void

    @State private var isRecording = false
    @State private var localMonitor: Any?

    var body: some View {
        Button {
            isRecording ? stopRecording() : startRecording()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isRecording ? "record.circle" : "keyboard")
                    .font(.system(size: 12, weight: .semibold))
                Text(isRecording ? "按下新快捷键" : shortcut.displayString)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isRecording ? DesignSystem.primary : DesignSystem.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(isRecording ? DesignSystem.primaryContainer.opacity(0.5) : DesignSystem.surfaceContainer)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("点击后按下新的全局快捷键，按 Esc 取消")
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        stopRecording()
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return nil
            }

            guard let newShortcut = MacQuickCaptureShortcut(event: event) else {
                NSSound.beep()
                return nil
            }

            shortcut = newShortcut
            onChange(newShortcut)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }
}
#endif
