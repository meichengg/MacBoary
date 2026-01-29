//
//  HotkeyManager.swift
//  macboary
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation
import Carbon
import Cocoa

@MainActor
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var callback: (() -> Void)?
    
    private init() {
        // Listen for blacklist changes to update immediately
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBlacklistChange),
            name: .blacklistChanged,
            object: nil
        )
    }
    
    func register(shortcut: GlobalKeyboardShortcut, callback: @escaping () -> Void) {
        self.callback = callback
        
        // Clean up previous tap if exists
        unregister()
        
        // Check blacklist
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleId = frontApp.bundleIdentifier,
           SettingsManager.shared.isAppBlacklisted(bundleId: bundleId) {
            print("🚫 App \(bundleId) is blacklisted. Skipping registration.")
            return
        }
        
        // We need to capture events to suppress them from RDP
        // Capture BOTH KeyDown and KeyUp to prevent "V Up" leakage which might confuse RDP/Windows
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let observer = refcon {
                    let mySelf = Unmanaged<HotkeyManager>.fromOpaque(observer).takeUnretainedValue()
                    if mySelf.handleEvent(event, type: type) {
                         // Suppress event
                         return nil
                    }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("⚠️ Failed to create event tap. Accessibility permissions might be missing.")
            return
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        // Monitor app focus change for cleanup
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppResignActive), name: NSApplication.didResignActiveNotification, object: nil)
    }
    
    @objc private func handleAppResignActive() {
        // When MacBoary loses focus (user clicked away, or pasted), force a cleaner reset.
        // This ensures the Target App (RDP) receives a clean slate.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.performGlobalModifierReset()
        }
    }
    
    func unregister() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
    }
    
    // Track if we are currently suppressing a key cycle
    private var isSuppressingCurrentKey = false
    
    // Returns true if event handled (should be suppressed)
    private func handleEvent(_ event: CGEvent, type: CGEventType) -> Bool {
        // Check if event matches shortcut
        let shortcut = SettingsManager.shared.shortcut
        let keyCode = Int64(event.getIntegerValueField(.keyboardEventKeycode))
        
        // Only check keycode first for performance
        if keyCode != Int64(shortcut.keyCode) {
            return false
        }
        
        if type == .keyDown {
            // Modifiers check
            let flags = event.flags
            let targetFlags = carbonModifiersToCGEventFlags(shortcut.modifiers)
            
            // Ignore non-modifier flags
            let ignoredFlags: CGEventFlags = [.maskAlphaShift, .maskNumericPad, .maskHelp, .maskNonCoalesced]
            let relevantFlags = flags.subtracting(ignoredFlags)
            let requiredMask: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
            
            let cleanFlags = relevantFlags.intersection(requiredMask)
            let cleanTarget = targetFlags.intersection(requiredMask)
            
            if cleanFlags == cleanTarget {
                // Match Found!
                isSuppressingCurrentKey = true
                
                // ANTI-LEAK STRATEGY V15: "Event-Agnostic Global Reset"
                // Persistent holds and delayed cleanups are causing sticky keys because 
                // we are fighting the OS's own key-repeat and state sync logic.
                //
                // Solution: "Clean on Entry".
                // 1. We STOP trying to manipulate RDP state blindly from the background.
                // 2. We just Activate MacBoary immediately.
                // 3. We rely on a Notification Observer (added in init) to trigger a cleaning burst 
                //    the moment MacBoary takes focus.
                
                print("⚡️ Hotkey intercepted. Activating MacBoary immediately (V15).")
                
                // V19: Capture Target App ID
                // We save who we are stealing focus FROM, so PasteService knows who to paste TO.
                if let frontApp = NSWorkspace.shared.frontmostApplication {
                    PasteService.shared.targetAppBundleId = frontApp.bundleIdentifier
                    PasteService.shared.targetApp = frontApp
                    print("🎯 Target App Captured: \(frontApp.bundleIdentifier ?? "Unknown")")
                }
                
                DispatchQueue.main.async { [weak self] in
                    NSApp.activate(ignoringOtherApps: true)
                    self?.callback?()
                    
                    // Trigger "Clean Entry" - Force release all modifiers on the event tap
                    // This ensures that whatever state RDP was in, the OS sees "Up" events now.
                    self?.performGlobalModifierReset()
                }
                
                // Swallow 'V'
                return true
            }
        } else if type == .keyUp {
            // If we suppressed the Down event for this key, we MUST suppress the Up event too.
            // Otherwise RDP sees "V Up" without "V Down", which is anomalous and leaves Win Key processed as "unused" logic.
            if isSuppressingCurrentKey {
                isSuppressingCurrentKey = false
                print("⚡️ Hotkey KeyUp suppressed.")
                return true
            }
        }
        
        return false
    }
    
    @objc private func handleBlacklistChange() {
        // Re-register to respect new blacklist settings
        if let currentCallback = self.callback {
            register(shortcut: SettingsManager.shared.shortcut, callback: currentCallback)
        }
    }
    
    private func carbonModifiersToCGEventFlags(_ carbonModifiers: UInt32) -> CGEventFlags {
        var flags: CGEventFlags = []
        if (carbonModifiers & UInt32(cmdKey)) != 0 { flags.insert(.maskCommand) }
        if (carbonModifiers & UInt32(shiftKey)) != 0 { flags.insert(.maskShift) }
        if (carbonModifiers & UInt32(optionKey)) != 0 { flags.insert(.maskAlternate) }
        if (carbonModifiers & UInt32(controlKey)) != 0 { flags.insert(.maskControl) }
        return flags
    }
    
    private func performGlobalModifierReset() {
        let source = CGEventSource(stateID: .hidSystemState)
        let ctrlKey = CGKeyCode(kVK_Control)
        let modifiers: [Int] = [kVK_Command, kVK_Shift, kVK_Option] // Exclude Control from the list to release inside
        
        print("🧹 Performing Masked Modifier Reset (V17)...")
        
        // 1. Inject Control DOWN (The Mask)
        // This tells Windows: "Whatever key comes next is part of a combo, NOT a standalone tap"
        if let ctrlDown = CGEvent(keyboardEventSource: source, virtualKey: ctrlKey, keyDown: true) {
            ctrlDown.flags = .maskControl
            ctrlDown.post(tap: .cghidEventTap)
        }
        
        // 2. Release other modifiers (Command, Shift, Option)
        // Windows sees: Win+Ctrl release, Shift+Ctrl release... -> No Start Menu!
        for key in modifiers {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key), keyDown: false) {
                event.flags = .maskControl // Keep Control flag active
                event.post(tap: .cghidEventTap)
            }
        }
        
        // 3. Release Control UP (The Unmask)
        if let ctrlUp = CGEvent(keyboardEventSource: source, virtualKey: ctrlKey, keyDown: false) {
            ctrlUp.flags = []
            ctrlUp.post(tap: .cghidEventTap)
        }
        
        print("✅ Masked Reset Complete.")
    }
}
