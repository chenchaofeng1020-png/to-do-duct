#if os(macOS)
import AppKit
import Carbon
import Foundation

struct MacQuickCaptureShortcut: Equatable, Sendable {
    static let keyCodeDefaultsKey = "macQuickCaptureShortcutKeyCode"
    static let modifiersDefaultsKey = "macQuickCaptureShortcutModifiers"

    static let `default` = MacQuickCaptureShortcut(
        keyCode: UInt32(kVK_ANSI_C),
        carbonModifiers: UInt32(cmdKey | optionKey | shiftKey)
    )

    let keyCode: UInt32
    let carbonModifiers: UInt32

    init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    init?(event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !modifiers.intersection([.command, .option, .control, .shift]).isEmpty else {
            return nil
        }

        if Self.isModifierOnlyKey(event.keyCode) {
            return nil
        }

        self.init(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: Self.carbonModifiers(from: modifiers)
        )
    }

    static func load(from defaults: UserDefaults = .standard) -> MacQuickCaptureShortcut {
        let keyCode = (defaults.object(forKey: keyCodeDefaultsKey) as? NSNumber).map { UInt32(truncating: $0) }
        let modifiers = (defaults.object(forKey: modifiersDefaultsKey) as? NSNumber).map { UInt32(truncating: $0) }

        if let keyCode, let modifiers {
            return MacQuickCaptureShortcut(keyCode: keyCode, carbonModifiers: modifiers)
        }

        return .default
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(Int(keyCode), forKey: Self.keyCodeDefaultsKey)
        defaults.set(Int(carbonModifiers), forKey: Self.modifiersDefaultsKey)
    }

    var displayString: String {
        modifierSymbols + keySymbol
    }

    var modifierSymbols: String {
        var symbols = ""
        if carbonModifiers & UInt32(cmdKey) != 0 { symbols += "\u{2318}" }
        if carbonModifiers & UInt32(optionKey) != 0 { symbols += "\u{2325}" }
        if carbonModifiers & UInt32(controlKey) != 0 { symbols += "\u{2303}" }
        if carbonModifiers & UInt32(shiftKey) != 0 { symbols += "\u{21E7}" }
        return symbols
    }

    var keySymbol: String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space:
            return "Space"
        case kVK_Return:
            return "\u{21A9}"
        case kVK_Escape:
            return "Esc"
        case kVK_Tab:
            return "\u{21E5}"
        case kVK_Delete:
            return "\u{232B}"
        case kVK_ForwardDelete:
            return "\u{2326}"
        case kVK_LeftArrow:
            return "\u{2190}"
        case kVK_RightArrow:
            return "\u{2192}"
        case kVK_UpArrow:
            return "\u{2191}"
        case kVK_DownArrow:
            return "\u{2193}"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default:
            return keyCharacter ?? "Key \(keyCode)"
        }
    }

    private var keyCharacter: String? {
        guard
            let source = CGEventSource(stateID: .hidSystemState),
            let event = CGEvent(
                keyboardEventSource: source,
                virtualKey: CGKeyCode(keyCode),
                keyDown: true
            )
        else {
            return nil
        }

        guard let value = event.keyboardString(maxLength: 4), !value.isEmpty else {
            return nil
        }

        return value.uppercased()
    }

    private static func carbonModifiers(from modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if modifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if modifiers.contains(.option) { carbon |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbon |= UInt32(controlKey) }
        if modifiers.contains(.shift) { carbon |= UInt32(shiftKey) }
        return carbon
    }

    private static func isModifierOnlyKey(_ keyCode: UInt16) -> Bool {
        [
            UInt16(kVK_Command),
            UInt16(kVK_RightCommand),
            UInt16(kVK_Option),
            UInt16(kVK_RightOption),
            UInt16(kVK_Control),
            UInt16(kVK_RightControl),
            UInt16(kVK_Shift),
            UInt16(kVK_RightShift),
            UInt16(kVK_CapsLock),
            UInt16(kVK_Function)
        ].contains(keyCode)
    }
}

private extension CGEvent {
    func keyboardString(maxLength: Int) -> String? {
        var length = 0
        var chars = [UniChar](repeating: 0, count: maxLength)
        keyboardGetUnicodeString(maxStringLength: maxLength, actualStringLength: &length, unicodeString: &chars)
        guard length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length)
    }
}
#endif
