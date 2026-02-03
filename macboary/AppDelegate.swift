//
//  AppDelegate.swift
//  macboary
//
//  Created by Marco Baeuml on 24/01/2026.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy based on settings
        SettingsManager.shared.updateDockIconVisibility()
        
        // Setup menu bar
        menuBarController = MenuBarController()
        
        // Always try to register hotkey (will work if permission is granted)
        registerHotkey()
        
        // Show permission requests in order: 1) Encryption, 2) Keychain, 3) Accessibility
        showPermissionsSequentially()
        
        // Listen for permission changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(permissionGranted),
            name: .permissionGranted,
            object: nil
        )
        
        // Listen for shortcut changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutDidChange),
            name: .shortcutChanged,
            object: nil
        )
        
        // Hide main window if it exists (we're a menu bar app)
        NSApp.windows.forEach { window in
            if window.title != "Macory Settings" && window.title != "About Macory" {
                window.orderOut(nil)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
        ClipboardManager.shared.stopMonitoring()
    }
    
    // MARK: - Dock Menu
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let settings = SettingsManager.shared
        
        let showItem = NSMenuItem(title: settings.localized("menu_show_history"), action: #selector(showHistoryFromDock), keyEquivalent: "")
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let clearItem = NSMenuItem(title: settings.localized("menu_clear_history"), action: #selector(clearHistoryFromDock), keyEquivalent: "")
        menu.addItem(clearItem)
        
        return menu
    }
    
    @MainActor @objc private func showHistoryFromDock() {
        FloatingPanelController.shared.showPanel()
    }
    
    @MainActor @objc private func clearHistoryFromDock() {
        menuBarController?.clearHistory()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        FloatingPanelController.shared.showPanel()
        return false
    }
    
    @MainActor private func registerHotkey() {
        let shortcut = SettingsManager.shared.shortcut
        HotkeyManager.shared.register(shortcut: shortcut) {
            FloatingPanelController.shared.togglePanel()
        }
    }
    
    @MainActor @objc private func shortcutDidChange() {
        registerHotkey()
        menuBarController?.updateMenu()
    }
    
    @MainActor @objc private func permissionGranted() {
        // Permission was granted, re-register hotkey to ensure it works
        registerHotkey()
        
        // Note: Do NOT show panel automatically on grant, let user open it via Hotkey or Dock
    }
    
    // MARK: - Permission Sequence
    @MainActor
    private func showPermissionsSequentially() {
        // Step 1: Show encryption opt-in dialog on first launch
        // Using SettingManager constant for consistency
        if UserDefaults.standard.object(forKey: SettingsManager.shared.encryptionEnabledKey) == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showEncryptionOptIn { encryptionEnabled in
                    
                    // Step 2: Show password prompt if encryption is enabled
                    if encryptionEnabled {
                        self.showPasswordPrompt {
                             self.checkAccessibilityBlocking()
                        }
                    } else {
                        self.checkAccessibilityBlocking()
                    }
                }
            }
        } else if SettingsManager.shared.encryptionEnabled && EncryptionService.shared.isConfigured && !EncryptionService.shared.isUnlocked {
            // Encryption enabled but not unlocked - show password prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showPasswordPrompt {
                    self.checkAccessibilityBlocking()
                }
            }
        } else {
            // Not first launch and no password needed
            checkAccessibilityBlocking()
        }
    }
    
    @MainActor
    private func checkAccessibilityBlocking() {
        // Loop until permission is granted or user quits
        if !PermissionManager.shared.hasAccessibilityPermission {
             let alert = NSAlert()
             alert.messageText = "Accessibility Permission Required"
             alert.informativeText = "MacBoary needs Accessibility access to copy/paste. Please grant access in System Settings."
             alert.alertStyle = .critical
             alert.addButton(withTitle: "Open Settings")
             alert.addButton(withTitle: "Quit")
             
             let response = alert.runModal()
             if response == .alertFirstButtonReturn {
                 PermissionManager.shared.openAccessibilityPreferences()
                 
                 // Show "Waiting" confirmation
                 let waitAlert = NSAlert()
                 waitAlert.messageText = "Waiting for Permission..."
                 waitAlert.informativeText = "1. Find 'MacBoary' in the list.\n2. Click the checkbox to enable it.\n3. If already enabled, toggle it OFF and ON again.\n4. Click 'Done' below."
                 waitAlert.addButton(withTitle: "Done")
                 
                 let _ = waitAlert.runModal()
                 
                 // Check immediately after they say they are done
                 if PermissionManager.shared.hasAccessibilityPermission {
                     // Success!
                     FloatingPanelController.shared.setReady(true)
                     registerHotkey()
                 } else {
                     // Still failed? TCC issue likely
                     let failAlert = NSAlert()
                     failAlert.messageText = "Permission Not Detected"
                     failAlert.informativeText = "macOS controls this permission strictly.\n\nTry these steps:\n- Remove MacBoary from the list (use '-' button)\n- Drag MacBoary into the list again\n- Or restart the app."
                     failAlert.alertStyle = .warning
                     failAlert.addButton(withTitle: "Try Again")
                     failAlert.addButton(withTitle: "Quit")
                     
                     let failResponse = failAlert.runModal()
                     if failResponse == .alertFirstButtonReturn {
                         checkAccessibilityBlocking()
                     } else {
                         NSApp.terminate(nil)
                     }
                 }
             } else {
                 NSApp.terminate(nil)
             }
        } else {
             // Permission Granted / Already Present
             FloatingPanelController.shared.setReady(true)
             registerHotkey()
             // Do NOT show panel automatically. User must use hotkey.
        }
    }
    
    @MainActor
    private func showEncryptionOptIn(completion: @escaping (Bool) -> Void) {
        let settings = SettingsManager.shared
        let alert = NSAlert()
        alert.messageText = settings.localized("encrypt_opt_in_title")
        alert.informativeText = settings.localized("encrypt_opt_in_message")
        alert.alertStyle = .informational
        alert.icon = NSImage(named: "AboutIcon")
        alert.addButton(withTitle: settings.localized("encrypt_opt_in_enable"))
        alert.addButton(withTitle: settings.localized("encrypt_opt_in_disable"))
        
        let response = alert.runModal()
        let enabled = (response == .alertFirstButtonReturn)
        
        SettingsManager.shared.encryptionEnabled = enabled
        
        completion(enabled)
    }
    
    private var passwordWindow: NSWindow?
    
    @MainActor
    private func showPasswordPrompt(completion: @escaping () -> Void) {
        let isConfigured = EncryptionService.shared.isConfigured
        
        let passwordView = PasswordPromptView(
            isSettingPassword: !isConfigured,
            onSuccess: { [weak self] in
                self?.passwordWindow?.close()
                self?.passwordWindow = nil
                completion()
            },
            onCancel: { [weak self] in
                self?.passwordWindow?.close()
                self?.passwordWindow = nil
                // User cancelled password setup - disable encryption
                if !isConfigured {
                    SettingsManager.shared.encryptionEnabled = false
                }
                completion()
            }
        )
        
        let hostingController = NSHostingController(rootView: passwordView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = isConfigured ? "Unlock MacBoary" : "Set Password"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 320, height: 200))
        window.center()
        window.level = .floating
        
        passwordWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
