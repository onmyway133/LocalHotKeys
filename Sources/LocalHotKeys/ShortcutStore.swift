import AppKit

/// Persists user-customized shortcut overrides in UserDefaults.
/// Also maintains a registry of all declared shortcuts for conflict detection.
@MainActor
final class ShortcutStore {
    static let shared = ShortcutStore()
    private let defaults = UserDefaults.standard

    // MARK: - Registry

    private var registry: [String: Shortcut] = [:]

    func register(_ shortcut: Shortcut) {
        registry[shortcut.id] = shortcut
    }

    /// Returns the registered shortcut that already uses the given key+modifiers,
    /// excluding the shortcut being edited (by id).
    func conflict(key: Key, modifiers: NSEvent.ModifierFlags, excluding id: String) -> Shortcut? {
        registry.values.first {
            $0.id != id && $0.key == key && $0.modifiers == modifiers
        }
    }

    private func keyCodeKey(for id: String) -> String { "LocalShortcuts_\(id)_keyCode" }
    private func modifiersKey(for id: String) -> String { "LocalShortcuts_\(id)_modifiers" }

    func key(for id: String) -> Key? {
        guard defaults.object(forKey: keyCodeKey(for: id)) != nil else { return nil }
        let code = UInt16(defaults.integer(forKey: keyCodeKey(for: id)))
        return Key(keyCode: code)
    }

    func modifiers(for id: String) -> NSEvent.ModifierFlags? {
        guard defaults.object(forKey: modifiersKey(for: id)) != nil else { return nil }
        return NSEvent.ModifierFlags(rawValue: UInt(defaults.integer(forKey: modifiersKey(for: id))))
    }

    func set(key: Key?, modifiers: NSEvent.ModifierFlags, for id: String) {
        if let key {
            defaults.set(Int(key.keyCode), forKey: keyCodeKey(for: id))
            defaults.set(Int(modifiers.rawValue), forKey: modifiersKey(for: id))
        } else {
            reset(for: id)
        }
    }

    func reset(for id: String) {
        defaults.removeObject(forKey: keyCodeKey(for: id))
        defaults.removeObject(forKey: modifiersKey(for: id))
    }
}
