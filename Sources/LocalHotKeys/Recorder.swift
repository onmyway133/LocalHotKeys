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
public struct Recorder: NSViewRepresentable {
    private let shortcut: Shortcut

    public init(shortcut: Shortcut) {
        self.shortcut = shortcut
    }

    public func makeNSView(context: Context) -> RecorderNSView {
        RecorderNSView(shortcut: shortcut)
    }

    public func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.shortcut = shortcut
        nsView.refresh()
    }
}

// MARK: - RecorderNSView

public final class RecorderNSView: NSView {
    public var shortcut: Shortcut
    private var isRecording = false
    private var localMonitor: Any?

    private lazy var shortcutLabel: NSTextField = {
        let f = NSTextField(labelWithString: "")
        f.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        f.alignment = .center
        f.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return f
    }()

    private lazy var clearButton: NSButton = {
        let b = NSButton(frame: .zero)
        b.bezelStyle = .circular
        b.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear")
        b.imageScaling = .scaleProportionallyDown
        b.isBordered = false
        b.target = self
        b.action = #selector(clearShortcut)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.setContentHuggingPriority(.required, for: .vertical)
        return b
    }()

    public init(shortcut: Shortcut) {
        self.shortcut = shortcut
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    public override var intrinsicContentSize: NSSize {
        NSSize(width: 120, height: 24)
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 12  // capsule (height / 2)
        layer?.borderWidth = 1

        addSubview(shortcutLabel)
        addSubview(clearButton)

        shortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            shortcutLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            shortcutLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            shortcutLabel.trailingAnchor.constraint(lessThanOrEqualTo: clearButton.leadingAnchor, constant: -4),

            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 14),
            clearButton.heightAnchor.constraint(equalToConstant: 14),
        ])

        let click = NSClickGestureRecognizer(target: self, action: #selector(startRecording))
        addGestureRecognizer(click)

        refresh()
    }

    public func refresh() {
        let hasShortcut = shortcut.key != nil

        if isRecording {
            shortcutLabel.stringValue = "Type shortcut…"
            shortcutLabel.textColor = .secondaryLabelColor
        } else if hasShortcut {
            shortcutLabel.stringValue = shortcut.displayString
            shortcutLabel.textColor = .labelColor
        } else {
            shortcutLabel.stringValue = "Record Shortcut"
            shortcutLabel.textColor = .secondaryLabelColor
        }

        clearButton.isHidden = !hasShortcut || isRecording

        layer?.borderColor = isRecording
            ? NSColor.controlAccentColor.cgColor
            : NSColor.separatorColor.cgColor
        layer?.backgroundColor = isRecording
            ? NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
            : NSColor.controlBackgroundColor.cgColor
    }

    @objc private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        refresh()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])

        if event.keyCode == Key.escape.keyCode {
            // cancel — restore previous
        } else if event.keyCode == Key.delete.keyCode && modifiers.isEmpty {
            shortcut.reset()
        } else {
            shortcut.set(key: Key(keyCode: event.keyCode), modifiers: modifiers)
        }

        stopRecording()
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        refresh()
    }

    @objc private func clearShortcut() {
        shortcut.reset()
        refresh()
    }
}
