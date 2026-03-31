//
//  GlobalHotKeyManager.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import AppKit
import Carbon

class GlobalHotKeyManager {
    static let shared = GlobalHotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var onHotKeyPress: (() -> Void)?
    
    private init() {}
    
    func register(keyCode: UInt32, modifiers: NSEvent.ModifierFlags, block: @escaping () -> Void) -> Bool {
        onHotKeyPress = block

        // Install the Carbon event handler only once for the lifetime of the singleton.
        installEventHandlerIfNeeded()

        // Unregister the previous hotkey before registering the new one.
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x7067656e), id: 1) // 'pgen'
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, carbonModifiers(from: modifiers), hotKeyID,
                                         GetApplicationEventTarget(), 0, &ref)
        if status == noErr {
            hotKeyRef = ref
            return true
        }
        return false
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
        if let h = eventHandler { RemoveEventHandler(h); eventHandler = nil }
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        // kEventClassKeyboard = 'keyb' = 0x6b657962, kEventHotKeyPressed = 1
        var eventSpec = EventTypeSpec(eventClass: OSType(0x6b657962), eventKind: UInt32(1))
        let handler: EventHandlerProcPtr = { _, _, userData -> OSStatus in
            guard let userData else { return noErr }
            Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue().onHotKeyPress?()
            return noErr
        }
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventSpec, userData, &eventHandler)
    }
    
    private func carbonModifiers(from nseventModifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if nseventModifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if nseventModifiers.contains(.shift) { carbon |= UInt32(shiftKey) }
        if nseventModifiers.contains(.option) { carbon |= UInt32(optionKey) }
        if nseventModifiers.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }
}
