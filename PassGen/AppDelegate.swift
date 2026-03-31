//
//  AppDelegate.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let settingsStore = SettingsStore()
    private var eventMonitor: Any?
    private var keyMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var isGenerating = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.windows.forEach { $0.close() }
        setupStatusItem()
        setupPopover()
        setupGlobalHotKey()
    }

    // MARK: - Global hotkey — generate & copy without opening PassGen

    private func setupGlobalHotKey() {
        settingsStore.$hotKeyCode
            .combineLatest(settingsStore.$hotKeyModifiers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (keyCode, modifiers) in
                self?.registerHotKey(keyCode: keyCode, modifiers: modifiers)
            }
            .store(in: &cancellables)
    }

    private func registerHotKey(keyCode: Int, modifiers: Int) {
        let modFlags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        let success = GlobalHotKeyManager.shared.register(keyCode: UInt32(keyCode), modifiers: modFlags) { [weak self] in
            self?.generateAndCopy()
        }
        settingsStore.isHotKeyRegistered = success
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
        
        if event.type == .rightMouseUp {
            if popover.isShown { closePopover() }
            showContextMenu()
            return
        }
        
        popover.isShown ? closePopover() : openPopover()
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async { self?.closePopover() }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                if NSApp.keyWindow?.firstResponder is ShortcutRecorderNSView { return event }
                DispatchQueue.main.async { self?.closePopover() }
                return nil
            }
            return event
        }
    }

    private func closePopover() {
        if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
        if let m = keyMonitor   { NSEvent.removeMonitor(m); keyMonitor   = nil }
        popover.performClose(nil)
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
        
        if let button = statusItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        }
    }

    @objc private func openPopoverFromMenu() { openPopover() }

    @objc func generateAndCopy() {
        guard !isGenerating else { return }
        isGenerating = true
        let pool = settingsStore.characterPool
        let length = Int(settingsStore.passwordLength)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self, let password = PasswordGenerator.generate(length: length, from: pool) else {
                DispatchQueue.main.async { self?.isGenerating = false }
                return
            }
            DispatchQueue.main.async {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(password, forType: .string)
                self.settingsStore.addToHistory(password)
                self.isGenerating = false
            }
        }
    }
}
