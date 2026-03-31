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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // Close any windows SwiftUI might auto-open (e.g. Settings scene)
        NSApp.windows.forEach { $0.close() }
        setupStatusItem()
        setupPopover()
    }

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
            showContextMenu()
            return
        }

        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()

        // Close on outside click
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }

        // Close on Escape
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.closePopover()
                return nil
            }
            return event
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor { NSEvent.removeMonitor(monitor); eventMonitor = nil }
        if let monitor = keyMonitor   { NSEvent.removeMonitor(monitor); keyMonitor   = nil }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let generateItem = NSMenuItem(title: "Generate & Copy New Password", action: #selector(generateAndCopy), keyEquivalent: "")
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

    @objc private func openPopoverFromMenu() {
        openPopover()
    }

    @objc private func generateAndCopy() {
        let pool = settingsStore.characterPool
        let length = Int(settingsStore.passwordLength)
        guard let password = PasswordGenerator.generate(length: length, from: pool) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(password, forType: .string)
        settingsStore.addToHistory(password)
    }
}
