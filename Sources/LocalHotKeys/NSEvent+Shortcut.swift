import AppKit

public extension NSEvent {
    /// Returns true if this keyDown event matches the given shortcut's current binding.
    func matches(_ shortcut: Shortcut) -> Bool {
        guard let key = shortcut.key else { return false }
        let relevant = modifierFlags.intersection([.command, .option, .control, .shift])
        return keyCode == key.keyCode && relevant == shortcut.modifiers
    }
}
