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
    
    override init() {
        super.init()
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = false
        }
        
        statusItem?.menu = createMenu()
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Show History
        let showHistoryItem = NSMenuItem(
            title: "Show History",
            action: #selector(showHistory),
            keyEquivalent: ""
        )
        showHistoryItem.target = self
        
        // Add keyboard shortcut display
        let shortcut = SettingsManager.shared.shortcut.displayString
        showHistoryItem.title = "Show History (\(shortcut))"
        
        menu.addItem(showHistoryItem)
        menu.addItem(NSMenuItem.separator())
        
        // Clear History
        let clearItem = NSMenuItem(
            title: "Clear History",
            action: #selector(clearHistory),
            keyEquivalent: ""
        )
        clearItem.target = self
        menu.addItem(clearItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // About
        let aboutItem = NSMenuItem(
            title: "About Macory",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Macory",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    func updateMenu() {
        statusItem?.menu = createMenu()
    }
    
    @objc private func showHistory() {
        FloatingPanelController.shared.showPanel()
    }
    
    @objc func clearHistory() {
        // Bring app to front if needed for the alert
        NSApp.activate(ignoringOtherApps: true)
        
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History?"
        alert.informativeText = "This will remove items from your clipboard history. This action cannot be undone."
        alert.alertStyle = .warning
        
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        
        let checkbox = NSButton(checkboxWithTitle: "Also clear pinned items", target: nil, action: nil)
        checkbox.state = .off
        checkbox.sizeToFit() // Ensure text is visible
        alert.accessoryView = checkbox
        
        if alert.runModal() == .alertFirstButtonReturn {
            let includePinned = (checkbox.state == .on)
            ClipboardManager.shared.clearHistory(includePinned: includePinned)
        }
    }
    
    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "Macory Settings"
            settingsWindow?.center()
            settingsWindow?.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func openAbout() {
        if aboutWindow == nil {
            aboutWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 350),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            aboutWindow?.title = "About Macory"
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
