//
//  AppDelegate.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let settingsStore = SettingsStore()
    private var eventMonitor: Any?
    private var keyMonitor: Any?
    private var globalHotKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.windows.forEach { $0.close() }
        setupStatusItem()
        setupPopover()
        setupGlobalHotKey()
    }

    // MARK: - Global hotkey — generate & copy without opening PassGen

    private func setupGlobalHotKey() {
        // Request Accessibility access — prompts the user and adds app to the list
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        globalHotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let targetMods = NSEvent.ModifierFlags(rawValue: UInt(self.settingsStore.hotKeyModifiers))
            guard flags == targetMods, event.keyCode == UInt16(self.settingsStore.hotKeyCode) else { return }
            DispatchQueue.main.async { self.generateAndCopy() }
        }
    }

    // MARK: - Status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = "PassGenStatusItem"

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "key.fill", accessibilityDescription: "PassGen")
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .applicationDefined
        popover.contentViewController = NSHostingController(
            rootView: ContentView().environmentObject(settingsStore)
        )
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp { showContextMenu(); return }
        popover.isShown ? closePopover() : openPopover()
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                // Let the shortcut recorder handle Escape itself (cancels recording)
                if NSApp.keyWindow?.firstResponder is ShortcutRecorderNSView { return event }
                self?.closePopover()
                return nil
            }
            return event
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
        if let m = keyMonitor   { NSEvent.removeMonitor(m); keyMonitor   = nil }
    }

    // MARK: - Context menu

    private func showContextMenu() {
        let menu = NSMenu()
        let keyChar = ShortcutRecorderNSView.keyString(for: UInt16(settingsStore.hotKeyCode))
        let keyEquiv = keyChar == "?" ? "" : keyChar.lowercased()
        let mods = NSEvent.ModifierFlags(rawValue: UInt(settingsStore.hotKeyModifiers))
        let generateItem = NSMenuItem(title: "Generate & Copy New Password", action: #selector(generateAndCopy), keyEquivalent: keyEquiv)
        generateItem.keyEquivalentModifierMask = mods
        generateItem.target = self
        menu.addItem(generateItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Open PassGen", action: #selector(openPopoverFromMenu), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit PassGen", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openPopoverFromMenu() { openPopover() }

    @objc func generateAndCopy() {
        let pool = settingsStore.characterPool
        let length = Int(settingsStore.passwordLength)
        guard let password = PasswordGenerator.generate(length: length, from: pool) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(password, forType: .string)
        settingsStore.addToHistory(password)
    }
}
