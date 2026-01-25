//
//  MenuBarController.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import AppKit
import SwiftUI

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    
    @MainActor override init() {
        super.init()
        setupStatusItem()
        NotificationCenter.default.addObserver(self, selector: #selector(updateMenu), name: .languageDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @MainActor private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = false
        }
        
        statusItem?.menu = createMenu()
    }
    
    @MainActor private func createMenu() -> NSMenu {
        let menu = NSMenu()
        let settings = SettingsManager.shared
        
        // Show History
        let showHistoryItem = NSMenuItem(
            title: settings.localized("menu_show_history"),
            action: #selector(showHistory),
            keyEquivalent: ""
        )
        showHistoryItem.target = self
        
        // Add keyboard shortcut display
        let shortcut = settings.shortcut.displayString
        showHistoryItem.title = "\(settings.localized("menu_show_history")) (\(shortcut))"
        
        menu.addItem(showHistoryItem)
        menu.addItem(NSMenuItem.separator())
        
        // Clear History
        let clearItem = NSMenuItem(
            title: settings.localized("menu_clear_history"),
            action: #selector(clearHistory),
            keyEquivalent: ""
        )
        clearItem.target = self
        menu.addItem(clearItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(
            title: settings.localized("menu_settings"),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // About
        let aboutItem = NSMenuItem(
            title: settings.localized("menu_about"),
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: settings.localized("menu_quit"),
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    @MainActor @objc func updateMenu() {
        statusItem?.menu = createMenu()
        // Update window titles if they are loaded
        if let window = settingsWindow {
            window.title = SettingsManager.shared.localized("settings_title")
        }
        if let window = aboutWindow {
            window.title = SettingsManager.shared.localized("about_title")
        }
    }
    
    @MainActor @objc private func showHistory() {
        FloatingPanelController.shared.showPanel()
    }
    
    @MainActor @objc func clearHistory() {
        // Bring app to front if needed for the alert
        NSApp.activate(ignoringOtherApps: true)
        let settings = SettingsManager.shared
        
        let alert = NSAlert()
        alert.messageText = settings.localized("alert_clear_title")
        alert.informativeText = settings.localized("alert_clear_desc")
        alert.alertStyle = .warning
        alert.icon = NSImage(named: "AboutIcon")
        
        alert.addButton(withTitle: settings.localized("clear"))
        alert.addButton(withTitle: settings.localized("cancel"))
        
        let checkbox = NSButton(checkboxWithTitle: settings.localized("clear_pinned"), target: nil, action: nil)
        checkbox.state = .off
        checkbox.sizeToFit() // Ensure text is visible
        alert.accessoryView = checkbox
        
        if alert.runModal() == .alertFirstButtonReturn {
            let includePinned = (checkbox.state == .on)
            ClipboardManager.shared.clearHistory(includePinned: includePinned)
        }
    }
    
    @MainActor @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = SettingsManager.shared.localized("settings_title")
            settingsWindow?.center()
            settingsWindow?.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @MainActor @objc private func openAbout() {
        if aboutWindow == nil {
            aboutWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 350),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            aboutWindow?.title = SettingsManager.shared.localized("about_title")
            aboutWindow?.center()
            aboutWindow?.contentView = NSHostingView(rootView: AboutView())
            aboutWindow?.isReleasedWhenClosed = false
        }
        
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
