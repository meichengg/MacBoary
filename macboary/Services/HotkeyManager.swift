//
//  HotkeyManager.swift
//  macboary
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation
import Carbon
import Cocoa

class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var callback: (() -> Void)?
    private var handlerUPP: EventHandlerUPP?
    
    private init() {}
    
    func register(shortcut: GlobalKeyboardShortcut, callback: @escaping () -> Void) {
        unregister()
        self.callback = callback
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handlerBlock: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.callback?()
            return noErr
        }
        
        self.handlerUPP = handlerBlock
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), handlerBlock, 1, &eventType, selfPtr, &eventHandler)
        
        var hotKeyID = EventHotKeyID(signature: OSType(0x4D435259), id: 1) // "MCRY"
        
        RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        if let handlerUPP = handlerUPP {
            // Note: EventHandlerUPP is a closure type in Swift, no need to explicitly dispose
            // The reference will be released when set to nil
            self.handlerUPP = nil
        }
        // Clear callback to break potential retain cycles
        self.callback = nil
    }
    
    deinit {
        unregister()
    }
}
