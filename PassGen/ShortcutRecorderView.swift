//
//  ShortcutRecorderView.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import AppKit
import SwiftUI

// MARK: - NSViewRepresentable wrapper

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var keyCode: Int
    @Binding var modifiers: Int

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onChange = { code, mods in
            keyCode = code
            modifiers = mods
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        guard !nsView.isRecording else { return }
        let currentMods = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        if nsView.keyCode != keyCode || nsView.modifiers != currentMods {
            nsView.keyCode = keyCode
            nsView.modifiers = currentMods
            nsView.refresh()
        }
    }
}

// MARK: - Custom NSView

class ShortcutRecorderNSView: NSView {
    var keyCode: Int = 26
    var modifiers: NSEvent.ModifierFlags = [.command, .shift]
    var onChange: ((Int, Int) -> Void)?
    private(set) var isRecording = false

    private let label = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1

        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.font = .systemFont(ofSize: 13)
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
        ])

        refresh()
    }

    func refresh() {
        if isRecording {
            label.stringValue = "Type shortcut…"
            label.textColor = .secondaryLabelColor
            layer?.borderColor = NSColor.controlAccentColor.cgColor
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
        } else {
            label.stringValue = Self.shortcutString(keyCode: keyCode, modifiers: modifiers)
            label.textColor = .labelColor
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        refresh()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }

        if event.keyCode == 53 { // Escape — cancel
            isRecording = false
            refresh()
            return
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // Require at least one of ⌘ ⌃ ⌥ to avoid plain key presses
        guard flags.contains(.command) || flags.contains(.control) || flags.contains(.option) else { return }

        keyCode = Int(event.keyCode)
        modifiers = flags
        isRecording = false
        onChange?(keyCode, Int(flags.rawValue))
        refresh()
    }

    override func resignFirstResponder() -> Bool {
        if isRecording {
            isRecording = false
            refresh()
        }
        return super.resignFirstResponder()
    }

    // MARK: - Formatting helpers

    static func shortcutString(keyCode: Int, modifiers: NSEvent.ModifierFlags) -> String {
        var result = ""
        if modifiers.contains(.control) { result += "⌃" }
        if modifiers.contains(.option)  { result += "⌥" }
        if modifiers.contains(.shift)   { result += "⇧" }
        if modifiers.contains(.command) { result += "⌘" }
        result += keyString(for: UInt16(keyCode))
        return result
    }

    static func keyString(for keyCode: UInt16) -> String {
        keyCodeMap[keyCode] ?? "?"
    }

    private static let keyCodeMap: [UInt16: String] = [
        0: "A",  1: "S",  2: "D",  3: "F",  4: "H",  5: "G",  6: "Z",  7: "X",
        8: "C",  9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P",
        37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
        18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
        25: "9", 26: "7", 28: "8", 29: "0",
        27: "-", 24: "=", 33: "[", 30: "]", 41: ";", 39: "'", 43: ",", 47: ".", 44: "/",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫",
        123: "←", 124: "→", 125: "↓", 126: "↑",
    ]
}
