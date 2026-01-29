//
//  PasteService.swift
//  macboary
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation
import AppKit
import Carbon
import ApplicationServices

class PasteService {
    static let shared = PasteService()
    
    // Store the bundle ID of the app we want to paste into
    // Captured by HotkeyManager before MacBoary takes focus.
    var targetAppBundleId: String?
    
    private let rdpClients = ["com.lemonmojo.RoyalTSX.App", "com.microsoft.rdc.macos", "com.microsoft.rdc.mac"]
    
    private init() {}
    
    func pasteToFrontApp() {
        // Check permissions
        guard AXIsProcessTrusted() else {
            print("⚠️ Cannot paste: Accessibility permission not granted")
            return
        }
        
        // Hide MacBoary to restore focus to previous app
        NSApp.hide(nil)
        
        // Determine delay based on target app (RDP needs more time for clipboard sync)
        var delay: TimeInterval = 0.2
        
        // Use the captured bundle ID (from HotkeyManager)
        if let bundleId = self.targetAppBundleId, rdpClients.contains(bundleId) {
            print("📋 Target is RDP (\(bundleId)). Using 0.7s sync delay.")
            delay = 0.7
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        var useControl = false
        
        if let frontApp = NSWorkspace.shared.frontmostApplication, let bundleId = frontApp.bundleIdentifier {
            if rdpClients.contains(bundleId) {
                print("📋 RDP Client detected (\(bundleId)), using Ctrl+V Sequence")
                useControl = true
            }
        }

        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode = CGKeyCode(kVK_ANSI_V)
        let modKeyCode = useControl ? CGKeyCode(kVK_Control) : CGKeyCode(kVK_Command)
        let flagMask: CGEventFlags = useControl ? .maskControl : .maskCommand
        
        // SEQUENCE: Mod Down -> V Down -> V Up -> Mod Up
        
        // 1. Modifier DOWN
        if let modDown = CGEvent(keyboardEventSource: source, virtualKey: modKeyCode, keyDown: true) {
            modDown.flags = flagMask
            modDown.post(tap: .cghidEventTap)
        }
        
        // 2. V DOWN
        if let vDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) {
            vDown.flags = flagMask
            vDown.post(tap: .cghidEventTap)
        }
        
        // 3. V UP
        if let vUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            vUp.flags = flagMask
            vUp.post(tap: .cghidEventTap)
        }
        
        // 4. Modifier UP
        if let modUp = CGEvent(keyboardEventSource: source, virtualKey: modKeyCode, keyDown: false) {
            modUp.flags = []
            modUp.post(tap: .cghidEventTap)
        }
        
        print("✅ Paste Sequence Injected (Explicit Modifiers)")
        
        // POST-PASTE CLEANUP (Strategy V17 - Masked Release)
        // Prevents Start Menu / Sticky Keys in RDP
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let src = CGEventSource(stateID: .hidSystemState)
            let ctrl = CGKeyCode(kVK_Control)
            let keys = [kVK_Shift, kVK_Command]
            
            // Mask Down
            if let d = CGEvent(keyboardEventSource: src, virtualKey: ctrl, keyDown: true) {
                d.flags = .maskControl
                d.post(tap: .cghidEventTap)
            }
            
            // Release Keys
            for k in keys {
                if let up = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(k), keyDown: false) {
                    up.flags = .maskControl
                    up.post(tap: .cghidEventTap)
                }
            }
            
            // Mask Up
            if let u = CGEvent(keyboardEventSource: src, virtualKey: ctrl, keyDown: false) {
                u.flags = []
                u.post(tap: .cghidEventTap)
            }
            print("🧹 Post-Paste Masked Cleanup Performed.")
        }
    }
}
