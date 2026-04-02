# LocalHotKeys

A lightweight Swift package for user-customizable **local** keyboard shortcuts on macOS. Unlike global hotkey libraries, shortcuts are matched inside `keyDown` via `NSEvent` — no system registration required.

## Requirements

- macOS 12+
- Swift 5.9+

## Installation

Add the package in Xcode via **File → Add Package Dependencies → Add Local** and select the `LocalHotKeys` folder.

## Usage

### 1. Declare shortcuts

```swift
import LocalHotKeys

extension LocalHotKeys.Shortcut {
    static let navigateLeft  = Shortcut("navigateLeft",  default: .leftBracket,  modifiers: .command)
    static let navigateRight = Shortcut("navigateRight", default: .rightBracket, modifiers: .command)
}
```

### 2. Match in keyDown

```swift
override func keyDown(with event: NSEvent) {
    if event.matches(.navigateLeft)  { handleLeft();  return }
    if event.matches(.navigateRight) { handleRight(); return }
    super.keyDown(with: event)
}
```

### 3. Let users customize in Settings

```swift
import SwiftUI
import LocalHotKeys

struct ShortcutsView: View {
    var body: some View {
        Form {
            LocalHotKeys.Recorder("Navigate Left",  shortcut: .navigateLeft)
            LocalHotKeys.Recorder("Navigate Right", shortcut: .navigateRight)
        }
    }
}
```

## How it works

- **Default binding** — each `Shortcut` is initialized with a default key + modifiers.
- **User override** — when the user records a new binding via `Recorder`, it's saved to `UserDefaults` under `LocalHotKeys_<id>_keyCode` and `LocalHotKeys_<id>_modifiers`.
- **Matching** — `event.matches(_:)` compares the event's `keyCode` and relevant modifier flags against the shortcut's current binding (override if set, otherwise default).
- **Reset** — pressing Delete in the recorder (or calling `shortcut.reset()`) removes the override and restores the default.

## API

### `Shortcut`

```swift
Shortcut(_ id: String, default key: Key?, modifiers: NSEvent.ModifierFlags = [])

shortcut.key         // current key (override ?? default)
shortcut.modifiers   // current modifiers (override ?? default)
shortcut.displayString  // e.g. "⌘["

shortcut.set(key:modifiers:)  // save user override
shortcut.reset()              // clear override, restore default
```

### `Key`

Common keys available as static constants:

```swift
.leftBracket, .rightBracket, .leftArrow, .rightArrow,
.upArrow, .downArrow, .space, .return, .escape, .tab,
.a ... .z (letters), .zero ... .nine (numbers), .f1 ... .f12
```

### `NSEvent.matches(_:)`

```swift
event.matches(.navigateLeft)  // true if keyCode + modifiers match
```

### `Recorder`

```swift
LocalHotKeys.Recorder("Label", shortcut: .myShortcut)
```

Click the field to record a new shortcut. Press Escape to cancel, Delete to clear.

## Reference

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) 
