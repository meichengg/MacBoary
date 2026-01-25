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
        
        // Request permissions if needed (but don't block hotkey registration)
        if !PermissionManager.shared.hasAccessibilityPermission {
            PermissionManager.shared.checkAndRequestPermissions()
        }
        
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
        
        // Open the floating panel to show it's ready
        FloatingPanelController.shared.showPanel()
    }
}
