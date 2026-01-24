//
//  PermissionManager.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation
import AppKit
import ApplicationServices

class PermissionManager {
    static let shared = PermissionManager()
    
    private init() {}
    
    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    func checkAndRequestPermissions() {
        if !hasAccessibilityPermission {
            requestAccessibilityPermission()
        }
    }
    
    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
