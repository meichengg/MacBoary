//
//  AppDelegate.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy based on settings
        SettingsManager.shared.updateDockIconVisibility()
        
        // Setup menu bar
        menuBarController = MenuBarController()
        
        // Request permissions
        PermissionManager.shared.checkAndRequestPermissions()
        
        // Register global hotkey
        registerHotkey()
        
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
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        FloatingPanelController.shared.showPanel()
        return false
    }
    
    private func registerHotkey() {
        let shortcut = SettingsManager.shared.shortcut
        HotkeyManager.shared.register(shortcut: shortcut) {
            FloatingPanelController.shared.togglePanel()
        }
    }
    
    @objc private func shortcutDidChange() {
        registerHotkey()
        menuBarController?.updateMenu()
    }
}
