//
//  FloatingPanel.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import AppKit
import SwiftUI
import Combine

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
        self.becomesKeyOnlyIfNeeded = false // Changed to false to always accept key
    }
    
    // Allow the panel to become key without activating the app
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// Separate observable class for selection state
class SelectionState: ObservableObject {
    @Published var index: Int = 0
    
    func moveUp() {
        if index > 0 {
            index -= 1
        }
    }
    
    func moveDown(maxIndex: Int) {
        if index < maxIndex {
            index += 1
        }
    }
    
    func reset() {
        index = 0
    }
}

class FloatingPanelController: NSObject {
    static let shared = FloatingPanelController()
    
    private var panel: FloatingPanel?
    private var previousApp: NSRunningApplication?
    private var hostingView: NSHostingView<AnyView>?
    
    let selectionState = SelectionState()
    var isVisible = false
    
    private var eventMonitor: Any?
    private var keyMonitor: Any?
    
    private override init() {
        super.init()
    }
    
    func showPanel() {
        // Store the currently active app before showing panel
        previousApp = NSWorkspace.shared.frontmostApplication
        
        // Reset selection
        selectionState.reset()
        
        // Create panel if needed
        if panel == nil {
            createPanel()
        }
        
        // Position near mouse
        positionPanelNearMouse()
        
        // Show panel and make it key
        panel?.orderFrontRegardless()
        panel?.makeKey()
        
        isVisible = true
        
        // Start monitoring for clicks outside and keyboard
        startEventMonitoring()
    }
    
    private func createPanel() {
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 450))
        
        let historyView = ClipboardHistoryView(
            selectionState: selectionState,
            onSelect: { [weak self] item in
                self?.selectItem(item)
            },
            onDelete: { [weak self] item in
                self?.deleteItem(item)
            }
        )
        
        let wrappedView = AnyView(historyView)
        hostingView = NSHostingView(rootView: wrappedView)
        hostingView?.layer?.cornerRadius = 12
        hostingView?.layer?.masksToBounds = true
        
        panel?.contentView = hostingView
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
        
        // Monitor for keyboard events - this intercepts at the app level
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isVisible else { return event }
            
            let items = ClipboardManager.shared.items
            
            switch event.keyCode {
            case 53: // Escape
                self.hidePanel()
                return nil // Consume event
                
            case 126: // Up arrow
                self.selectionState.moveUp()
                return nil // Consume event
                
            case 125: // Down arrow
                self.selectionState.moveDown(maxIndex: items.count - 1)
                return nil // Consume event
                
            case 36: // Return/Enter
                if self.selectionState.index >= 0 && self.selectionState.index < items.count {
                    self.selectItem(items[self.selectionState.index])
                }
                return nil // Consume event
                
            case 51: // Delete/Backspace
                if self.selectionState.index >= 0 && self.selectionState.index < items.count {
                    self.deleteItem(items[self.selectionState.index])
                }
                return nil // Consume event
                
            default:
                return event // Pass other keys through
            }
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
        let itemCount = ClipboardManager.shared.items.count
        ClipboardManager.shared.deleteItem(item)
        
        // Adjust selection if needed
        if selectionState.index >= itemCount - 1 && selectionState.index > 0 {
            selectionState.index -= 1
        }
    }
}
