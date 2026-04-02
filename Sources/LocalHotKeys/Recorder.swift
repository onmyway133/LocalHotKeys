import SwiftUI
import AppKit

/// A compact recorder field for assigning a local keyboard shortcut.
/// Does not include a label — style the surrounding UI yourself.
///
/// Usage:
/// ```swift
/// HStack {
///     Text("Navigate Left")
///     Spacer()
///     LocalHotKeys.Recorder(shortcut: .navigateLeft)
/// }
/// ```
public struct Recorder: View {
    private let shortcut: Shortcut

    public init(shortcut: Shortcut) {
        self.shortcut = shortcut
    }

    public var body: some View {
        RecorderField(shortcut: shortcut)
            .fixedSize()
    }
}

// MARK: - RecorderField (NSViewRepresentable)

private struct RecorderField: NSViewRepresentable {
    let shortcut: Shortcut

    func makeNSView(context: Context) -> RecorderNSView {
        RecorderNSView(shortcut: shortcut)
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.shortcut = shortcut
        nsView.refresh()
    }
}

// MARK: - RecorderNSView

public final class RecorderNSView: NSSearchField, NSSearchFieldDelegate {
    public var shortcut: Shortcut
    private var localMonitor: Any?
    private var canBecomeKey = false
    private var cancelButtonCell: NSButtonCell?

    public init(shortcut: Shortcut) {
        self.shortcut = shortcut
        super.init(frame: NSRect(x: 0, y: 0, width: 120, height: 24))
        configure()
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override var intrinsicContentSize: NSSize {
        NSSize(width: 120, height: 24)
    }

    public override var canBecomeKeyView: Bool { canBecomeKey }

    private func configure() {
        delegate = self
        placeholderString = "Record Shortcut"
        alignment = .center
        (cell as? NSSearchFieldCell)?.searchButtonCell = nil

        wantsLayer = true
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)

        // Must be last — save cancel button cell for show/hide
        cancelButtonCell = (cell as? NSSearchFieldCell)?.cancelButtonCell

        // Prevent receiving initial focus when the window opens
        Task { @MainActor [weak self] in
            self?.canBecomeKey = true
        }
    }

    public func refresh() {
        stringValue = shortcut.key != nil ? shortcut.displayString : ""
        (cell as? NSSearchFieldCell)?.cancelButtonCell = stringValue.isEmpty ? nil : cancelButtonCell
    }

    // MARK: - Focus / Recording

    public override func becomeFirstResponder() -> Bool {
        guard window != nil else { return false }
        let result = super.becomeFirstResponder()
        guard result else { return result }

        placeholderString = "Type shortcut…"
        hideCaret()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseUp, .rightMouseUp]) { [weak self] event in
            guard let self else { return event }

            // Click outside — stop recording, pass event through
            if event.type == .leftMouseUp || event.type == .rightMouseUp {
                let point = convert(event.locationInWindow, from: nil)
                if !bounds.insetBy(dx: -3, dy: -3).contains(point) {
                    blur()
                    return event
                }
                return nil
            }

            handleKeyEvent(event)
            return nil
        }

        return result
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])

        if event.keyCode == Key.escape.keyCode {
            // Cancel — keep existing shortcut
        } else if event.keyCode == Key.delete.keyCode && modifiers.isEmpty {
            shortcut.reset()
        } else {
            shortcut.set(key: Key(keyCode: event.keyCode), modifiers: modifiers)
        }

        refresh()
        blur()
    }

    private func stopRecording() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        placeholderString = "Record Shortcut"
        restoreCaret()
    }

    private func blur() {
        window?.makeFirstResponder(nil)
    }

    // MARK: - Caret

    private func hideCaret() {
        (currentEditor() as? NSTextView)?.insertionPointColor = .clear
    }

    private func restoreCaret() {
        (currentEditor() as? NSTextView)?.insertionPointColor = .controlTextColor
    }

    // MARK: - NSSearchFieldDelegate

    public func controlTextDidEndEditing(_ obj: Notification) {
        stopRecording()
    }

    public func controlTextDidChange(_ obj: Notification) {
        // User clicked the built-in × cancel button — clear the shortcut
        if stringValue.isEmpty {
            shortcut.reset()
        }
        (cell as? NSSearchFieldCell)?.cancelButtonCell = stringValue.isEmpty ? nil : cancelButtonCell
    }
}
