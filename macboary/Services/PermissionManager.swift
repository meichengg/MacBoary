//
//  PermissionManager.swift
//  macboary
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation
import AppKit
import ApplicationServices

class PermissionManager {
    static let shared = PermissionManager()
    
    private var permissionCheckTimer: Timer?
    var isRequestingPermission = false  // Made public for access check
    private var permissionRequestStarted = false  // Track if a request was initiated
    private var permissionCheckStartTime: Date?
    
    private init() {
        // Notifications removed
    }
    
    deinit {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
    
    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }
    
    func requestAccessibilityPermission() {
        isRequestingPermission = true
        permissionRequestStarted = true
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        
        // The system dialog only shows for a few seconds
        // After 3 seconds, allow the floating panel to open (dialog will be dismissed by then)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isRequestingPermission = false
        }
        
        // Start monitoring for permission decision (but don't block UI anymore)
        startPermissionDecisionMonitoring()
    }
    
    func checkAndRequestPermissions() {
        if !hasAccessibilityPermission {
            requestAccessibilityPermission()
        }
    }
    
    private func startPermissionDecisionMonitoring() {
        // Poll to detect when the user grants permission
        permissionCheckTimer?.invalidate()
        permissionCheckStartTime = Date()
        
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Timeout after 2 minutes
            if let startTime = self.permissionCheckStartTime, Date().timeIntervalSince(startTime) > 120 {
                timer.invalidate()
                self.permissionCheckTimer = nil
                self.isRequestingPermission = false
                self.permissionRequestStarted = false
                self.permissionCheckStartTime = nil
                return
            }
            
            if self.hasAccessibilityPermission {
                // Permission granted!
                timer.invalidate()
                self.permissionCheckTimer = nil
                self.isRequestingPermission = false
                self.permissionRequestStarted = false
                self.permissionCheckStartTime = nil
                
                self.closeSystemPreferences()
                // Notification removed
                
                // Notify that permission was granted
                NotificationCenter.default.post(name: .permissionGranted, object: nil)
            }
        }
    }
    
    func openAccessibilityPreferences() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            print("Failed to create accessibility preferences URL")
            return
        }
        NSWorkspace.shared.open(url)
        isRequestingPermission = true
        permissionRequestStarted = true
        
        // Allow panel to open after 3 seconds (user will have seen the System Preferences by then)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isRequestingPermission = false
        }
        
        // Start polling to detect when permission is granted
        startPermissionDecisionMonitoring()
    }
    
    private func closeSystemPreferences() {
        // Try to close System Preferences/System Settings
        let runningApps = NSWorkspace.shared.runningApplications
        
        // macOS 13+ uses "System Settings", older versions use "System Preferences"
        for app in runningApps {
            if app.bundleIdentifier == "com.apple.systempreferences" ||
               app.bundleIdentifier == "com.apple.Settings" {
                app.terminate()
                break
            }
        }
    }
}

extension Notification.Name {
    static let permissionGranted = Notification.Name("permissionGranted")
    static let permissionDenied = Notification.Name("permissionDenied")
}
