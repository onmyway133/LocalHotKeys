import Foundation
import Carbon

/// A keyboard key identified by its hardware keycode.
public struct Key: Hashable, Sendable {
    public let keyCode: UInt16

    public init(keyCode: UInt16) {
        self.keyCode = keyCode
    }
}

// MARK: - Common Keys

public extension Key {
    // Letters
    static let a = Key(keyCode: 0)
    static let s = Key(keyCode: 1)
    static let d = Key(keyCode: 2)
    static let f = Key(keyCode: 3)
    static let h = Key(keyCode: 4)
    static let g = Key(keyCode: 5)
    static let z = Key(keyCode: 6)
    static let x = Key(keyCode: 7)
    static let c = Key(keyCode: 8)
    static let v = Key(keyCode: 9)
    static let b = Key(keyCode: 11)
    static let q = Key(keyCode: 12)
    static let w = Key(keyCode: 13)
    static let e = Key(keyCode: 14)
    static let r = Key(keyCode: 15)
    static let y = Key(keyCode: 16)
    static let t = Key(keyCode: 17)
    static let one = Key(keyCode: 18)
    static let two = Key(keyCode: 19)
    static let three = Key(keyCode: 20)
    static let four = Key(keyCode: 21)
    static let six = Key(keyCode: 22)
    static let five = Key(keyCode: 23)
    static let equal = Key(keyCode: 24)
    static let nine = Key(keyCode: 25)
    static let seven = Key(keyCode: 26)
    static let minus = Key(keyCode: 27)
    static let eight = Key(keyCode: 28)
    static let zero = Key(keyCode: 29)
    static let rightBracket = Key(keyCode: 30)
    static let o = Key(keyCode: 31)
    static let u = Key(keyCode: 32)
    static let leftBracket = Key(keyCode: 33)
    static let i = Key(keyCode: 34)
    static let p = Key(keyCode: 35)
    static let `return` = Key(keyCode: 36)
    static let l = Key(keyCode: 37)
    static let j = Key(keyCode: 38)
    static let quote = Key(keyCode: 39)
    static let k = Key(keyCode: 40)
    static let semicolon = Key(keyCode: 41)
    static let backslash = Key(keyCode: 42)
    static let comma = Key(keyCode: 43)
    static let slash = Key(keyCode: 44)
    static let n = Key(keyCode: 45)
    static let m = Key(keyCode: 46)
    static let period = Key(keyCode: 47)
    static let tab = Key(keyCode: 48)
    static let space = Key(keyCode: 49)
    static let backtick = Key(keyCode: 50)
    static let delete = Key(keyCode: 51)
    static let escape = Key(keyCode: 53)

    // Arrow keys
    static let leftArrow  = Key(keyCode: 123)
    static let rightArrow = Key(keyCode: 124)
    static let downArrow  = Key(keyCode: 125)
    static let upArrow    = Key(keyCode: 126)

    // Function keys
    static let f1  = Key(keyCode: 122)
    static let f2  = Key(keyCode: 120)
    static let f3  = Key(keyCode: 99)
    static let f4  = Key(keyCode: 118)
    static let f5  = Key(keyCode: 96)
    static let f6  = Key(keyCode: 97)
    static let f7  = Key(keyCode: 98)
    static let f8  = Key(keyCode: 100)
    static let f9  = Key(keyCode: 101)
    static let f10 = Key(keyCode: 109)
    static let f11 = Key(keyCode: 103)
    static let f12 = Key(keyCode: 111)
}

// MARK: - Display

extension Key {
    /// A human-readable representation of this key (e.g. "[", "←").
    var displayString: String {
        switch self {
        case .leftBracket:  return "["
        case .rightBracket: return "]"
        case .leftArrow:    return "←"
        case .rightArrow:   return "→"
        case .upArrow:      return "↑"
        case .downArrow:    return "↓"
        case .space:        return "Space"
        case .return:       return "↩"
        case .delete:       return "⌫"
        case .escape:       return "⎋"
        case .tab:          return "⇥"
        default:
            // For letter/number keys, look up via key event
            return keyCodeToString(keyCode) ?? "(\(keyCode))"
        }
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        guard
            let dataRef = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData),
            let layoutData = unsafeBitCast(dataRef, to: CFData?.self)
        else { return nil }

        let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)
        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0

        let error = UCKeyTranslate(
            keyboardLayout,
            keyCode,
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            chars.count,
            &length,
            &chars
        )

        guard error == noErr, length > 0 else { return nil }
        return String(chars[0..<length].map { Character(Unicode.Scalar($0)!) }).uppercased()
    }
}
