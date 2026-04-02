import AppKit

/// A local keyboard shortcut with a stable id, a default binding, and optional user override.
public struct Shortcut: Sendable {
    public let id: String
    public let defaultKey: Key?
    public let defaultModifiers: NSEvent.ModifierFlags

    public init(_ id: String, default key: Key?, modifiers: NSEvent.ModifierFlags = []) {
        self.id = id
        self.defaultKey = key
        self.defaultModifiers = modifiers
    }

    // MARK: - Current Binding (user override → default)

    public var key: Key? {
        ShortcutStore.shared.key(for: id) ?? defaultKey
    }

    public var modifiers: NSEvent.ModifierFlags {
        ShortcutStore.shared.modifiers(for: id) ?? defaultModifiers
    }

    // MARK: - Mutation

    public func set(key: Key?, modifiers: NSEvent.ModifierFlags) {
        ShortcutStore.shared.set(key: key, modifiers: modifiers, for: id)
    }

    public func reset() {
        ShortcutStore.shared.reset(for: id)
    }

    // MARK: - Display

    public var displayString: String {
        guard let key else { return "None" }
        return modifiers.displayString + key.displayString
    }
}

// MARK: - Modifier display helper

extension NSEvent.ModifierFlags {
    var displayString: String {
        var result = ""
        if contains(.control) { result += "⌃" }
        if contains(.option)  { result += "⌥" }
        if contains(.shift)   { result += "⇧" }
        if contains(.command) { result += "⌘" }
        return result
    }
}
