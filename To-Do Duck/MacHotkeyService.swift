#if os(macOS)
import AppKit
import Carbon

private let macQuickCaptureHotKeyHandler: EventHandlerUPP = { _, eventRef, userData in
    guard let userData, let eventRef else {
        return noErr
    }

    let service = Unmanaged<MacHotkeyService>.fromOpaque(userData).takeUnretainedValue()
    return service.handleHotKeyEvent(eventRef)
}

final class MacHotkeyService {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let action: @Sendable () -> Void
    private let hotKeyID = EventHotKeyID(signature: FourCharCode(0x5444444B), id: 1)
    private var shortcut: MacQuickCaptureShortcut

    init(
        shortcut: MacQuickCaptureShortcut = .load(),
        action: @escaping @Sendable () -> Void
    ) {
        self.shortcut = shortcut
        self.action = action
    }

    deinit {
        unregister()
    }

    func register() {
        guard hotKeyRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            macQuickCaptureHotKeyHandler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )

        RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func updateShortcut(_ shortcut: MacQuickCaptureShortcut) {
        self.shortcut = shortcut
        unregister()
        register()
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    nonisolated func handleHotKeyEvent(_ eventRef: EventRef) -> OSStatus {
        var eventHotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &eventHotKeyID
        )

        guard status == noErr, eventHotKeyID.id == hotKeyID.id else {
            return noErr
        }

        DispatchQueue.main.async { [action] in
            action()
        }
        return noErr
    }
}
#endif
