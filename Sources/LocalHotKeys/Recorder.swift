import SwiftUI
import AppKit

/// A SwiftUI view that lets the user assign or clear a local keyboard shortcut.
///
/// Usage:
/// ```swift
/// LocalShortcuts.Recorder("Navigate Left", shortcut: .navigateLeft)
/// ```
public struct Recorder: View {
    private let label: String
    private let shortcut: Shortcut

    public init(_ label: String, shortcut: Shortcut) {
        self.label = label
        self.shortcut = shortcut
    }

    public var body: some View {
        HStack {
            Text(label)
            Spacer()
            RecorderField(shortcut: shortcut)
        }
    }
}

// MARK: - RecorderField (AppKit-backed)

private struct RecorderField: NSViewRepresentable {
    let shortcut: Shortcut

    func makeNSView(context: Context) -> RecorderNSView {
        RecorderNSView(shortcut: shortcut)
    }

    func updateNSView(_ view: RecorderNSView, context: Context) {
        view.shortcut = shortcut
        view.refresh()
    }
}

// MARK: - RecorderNSView

private final class RecorderNSView: NSView {
    var shortcut: Shortcut
    private var isRecording = false
    private var localMonitor: Any?

    private lazy var label: NSTextField = {
        let f = NSTextField(labelWithString: "")
        f.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        f.alignment = .center
        return f
    }()

    private lazy var clearButton: NSButton = {
        let b = NSButton(title: "×", target: self, action: #selector(clearShortcut))
        b.bezelStyle = .roundRect
        b.font = .systemFont(ofSize: 11)
        return b
    }()

    private lazy var container: NSView = {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.cornerRadius = 5
        v.layer?.borderWidth = 1
        return v
    }()

    init(shortcut: Shortcut) {
        self.shortcut = shortcut
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        addSubview(container)
        container.addSubview(label)
        addSubview(clearButton)

        container.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -6),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            clearButton.leadingAnchor.constraint(equalTo: container.trailingAnchor, constant: 4),
            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        refresh()

        let click = NSClickGestureRecognizer(target: self, action: #selector(startRecording))
        container.addGestureRecognizer(click)
    }

    func refresh() {
        label.stringValue = isRecording ? "Type shortcut…" : shortcut.displayString
        let hasSetting = shortcut.key != nil
        clearButton.isHidden = !hasSetting
        container.layer?.borderColor = isRecording
            ? NSColor.controlAccentColor.cgColor
            : NSColor.separatorColor.cgColor
        container.layer?.backgroundColor = isRecording
            ? NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
            : NSColor.controlBackgroundColor.cgColor
    }

    @objc private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        refresh()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil  // consume event
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        let key = Key(keyCode: event.keyCode)

        if event.keyCode == Key.escape.keyCode {
            // Cancel recording
        } else if event.keyCode == Key.delete.keyCode && modifiers.isEmpty {
            shortcut.reset()
        } else {
            shortcut.set(key: key, modifiers: modifiers)
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

    override func mouseDown(with event: NSEvent) {
        // Handled by gesture recognizer
    }
}
