//
//  FloatingPanel.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import AppKit
import SwiftUI

class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        // Panel configuration
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        
        // Don't show in dock or app switcher
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = true
    }
    
    // Allow the panel to become key without activating the app
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

class FloatingPanelController: NSObject, ObservableObject {
    static let shared = FloatingPanelController()
    
    private var panel: FloatingPanel?
    private var previousApp: NSRunningApplication?
    @Published var selectedIndex: Int = 0
    @Published var isVisible = false
    
    private var eventMonitor: Any?
    private var keyMonitor: Any?
    
    private override init() {
        super.init()
    }
    
    func showPanel() {
        // Store the currently active app before showing panel
        previousApp = NSWorkspace.shared.frontmostApplication
        
        // Create panel if needed
        if panel == nil {
            panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 450))
            
            let historyView = ClipboardHistoryView(
                selectedIndex: Binding(
                    get: { self.selectedIndex },
                    set: { self.selectedIndex = $0 }
                ),
                onSelect: { [weak self] item in
                    self?.selectItem(item)
                },
                onDelete: { [weak self] item in
                    self?.deleteItem(item)
                }
            )
            
            let hostingView = NSHostingView(rootView: historyView)
            hostingView.layer?.cornerRadius = 12
            hostingView.layer?.masksToBounds = true
            
            panel?.contentView = hostingView
        }
        
        // Position near mouse
        positionPanelNearMouse()
        
        // Show panel
        panel?.orderFrontRegardless()
        panel?.makeKey()
        
        selectedIndex = 0
        isVisible = true
        
        // Start monitoring for clicks outside and keyboard
        startEventMonitoring()
    }
    
    func hidePanel() {
        stopEventMonitoring()
        panel?.orderOut(nil)
        isVisible = false
    }
    
    func togglePanel() {
        if isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }
    
    private func positionPanelNearMouse() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let panelSize = panel.frame.size
        
        // Calculate position (prefer below and to the right of cursor)
        var x = mouseLocation.x - panelSize.width / 2
        var y = mouseLocation.y - panelSize.height - 10
        
        // Keep on screen
        let screenFrame = screen.visibleFrame
        
        if x < screenFrame.minX {
            x = screenFrame.minX + 10
        }
        if x + panelSize.width > screenFrame.maxX {
            x = screenFrame.maxX - panelSize.width - 10
        }
        if y < screenFrame.minY {
            y = mouseLocation.y + 20 // Show above cursor instead
        }
        if y + panelSize.height > screenFrame.maxY {
            y = screenFrame.maxY - panelSize.height - 10
        }
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    private func startEventMonitoring() {
        // Monitor for clicks outside panel
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel else { return }
            
            let mouseLocation = NSEvent.mouseLocation
            if !panel.frame.contains(mouseLocation) {
                self.hidePanel()
            }
        }
        
        // Monitor for keyboard events
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            return self.handleKeyEvent(event) ? nil : event
        }
    }
    
    private func stopEventMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard isVisible else { return false }
        
        let items = ClipboardManager.shared.items
        
        switch event.keyCode {
        case 53: // Escape
            hidePanel()
            return true
            
        case 126: // Up arrow
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return true
            
        case 125: // Down arrow
            if selectedIndex < items.count - 1 {
                selectedIndex += 1
            }
            return true
            
        case 36: // Return/Enter
            if selectedIndex >= 0 && selectedIndex < items.count {
                selectItem(items[selectedIndex])
            }
            return true
            
        case 51: // Delete/Backspace
            if selectedIndex >= 0 && selectedIndex < items.count {
                deleteItem(items[selectedIndex])
            }
            return true
            
        default:
            return false
        }
    }
    
    private func selectItem(_ item: ClipboardItem) {
        ClipboardManager.shared.selectItem(item)
        hidePanel()
        
        // Activate previous app and paste
        if let previousApp = previousApp {
            previousApp.activate()
            PasteService.shared.pasteToFrontApp()
        }
    }
    
    private func deleteItem(_ item: ClipboardItem) {
        let items = ClipboardManager.shared.items
        ClipboardManager.shared.deleteItem(item)
        
        // Adjust selection if needed
        if selectedIndex >= items.count - 1 && selectedIndex > 0 {
            selectedIndex -= 1
        }
    }
}
