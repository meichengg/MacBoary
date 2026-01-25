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
    
    private init() {}
    
    func pasteToFrontApp() {
        // Check if we have accessibility permission before attempting to post events
        guard AXIsProcessTrusted() else {
            print("⚠️ Cannot paste: Accessibility permission not granted")
            return
        }
        
        // Small delay to ensure window is closed and previous app is active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        // Create Cmd+V key event
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        
        // Key up
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
