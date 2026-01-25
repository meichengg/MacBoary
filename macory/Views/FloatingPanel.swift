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

// Separate observable class for selection and search state
class HistoryViewModel: ObservableObject {
    static let defaultPageSize = 20
    var pageSize: Int { Self.defaultPageSize }
    
    @Published var selectionIndex: Int = 0
    @Published var displayedLimit: Int = HistoryViewModel.defaultPageSize
    @Published var searchText: String = "" {
        didSet {
            // Reset selection and limit when search changes
            if oldValue != searchText {
                selectionIndex = 0
                displayedLimit = pageSize
            }
        }
    }
    
    func moveUp() {
        if selectionIndex > 0 {
            selectionIndex -= 1
        }
    }
    
    func moveDown(maxIndex: Int) {
        if selectionIndex < maxIndex {
            selectionIndex += 1
        }
    }
    
    func reset() {
        selectionIndex = 0
        displayedLimit = pageSize
        searchText = ""
    }
}

class FloatingPanelController: NSObject, NSWindowDelegate {
    static let shared = FloatingPanelController()
    
    private var panel: FloatingPanel?
    private var previousApp: NSRunningApplication?
    private var hostingView: NSHostingView<AnyView>?
    
    let viewModel = HistoryViewModel()
    var isVisible = false
    
    private var eventMonitor: Any?
    private var keyMonitor: Any?
    
    private override init() {
        super.init()
    }
    
    private var filteredItems: [ClipboardItem] {
        let items = ClipboardManager.shared.items
        if viewModel.searchText.isEmpty {
            return items
        }
        return items.filter { item in
            item.content.localizedCaseInsensitiveContains(viewModel.searchText)
        }
    }
    
    func showPanel() {
        // Store the currently active app before showing panel
        previousApp = NSWorkspace.shared.frontmostApplication
        
        // Reset selection
        viewModel.reset()
        
        // Create panel if needed
        if panel == nil {
            createPanel()
        }
        
        // Position panel based on settings
        positionPanel()
        
        // Show panel and make it key
        panel?.orderFrontRegardless()
        panel?.makeKey()
        
        isVisible = true
        
        // Start monitoring for clicks outside and keyboard
        startEventMonitoring()
    }
    
    private func createPanel() {
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 450))
        panel?.delegate = self
        
        let historyView = ClipboardHistoryView(
            viewModel: viewModel,
            onSelect: { [weak self] item in
                self?.selectItem(item)
            },
            onDelete: { [weak self] item in
                // We need to pass the original item, but deleteItem expects it
                self?.deleteItem(item)
            },
            onPin: { [weak self] item in
                self?.togglePin(item)
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
    
    private func positionPanel() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        
        let panelSize = panel.frame.size
        let screenFrame = screen.visibleFrame
        
        var x: CGFloat
        var y: CGFloat
        
        switch SettingsManager.shared.popupPosition {
        case .center:
            // Center of screen
            x = screenFrame.midX - panelSize.width / 2
            y = screenFrame.midY - panelSize.height / 2
            
        case .mouse:
            // Near mouse position
            let mouseLocation = NSEvent.mouseLocation
            x = mouseLocation.x - panelSize.width / 2
            y = mouseLocation.y - panelSize.height - 10
            
            // Adjust if below screen
            if y < screenFrame.minY {
                y = mouseLocation.y + 20 // Show above cursor instead
            }
        }
        
        // Keep on screen (applies to both modes)
        if x < screenFrame.minX {
            x = screenFrame.minX + 10
        }
        if x + panelSize.width > screenFrame.maxX {
            x = screenFrame.maxX - panelSize.width - 10
        }
        if y + panelSize.height > screenFrame.maxY {
            y = screenFrame.maxY - panelSize.height - 10
        }
        if y < screenFrame.minY {
            y = screenFrame.minY + 10
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
            
            // Allow typing in search field (don't capture if it's a character key, unless modifiers)
            // But we need to capture navigation keys
            
            let filtered = self.filteredItems
            
            switch event.keyCode {
            case 53: // Escape
                self.hidePanel()
                return nil // Consume event
                
            case 126: // Up arrow
                self.viewModel.moveUp()
                return nil // Consume event
                
            case 125: // Down arrow
                let maxIndex: Int
                if filtered.count > self.viewModel.displayedLimit {
                    // Include "Load More" button as the last selectable item
                    maxIndex = self.viewModel.displayedLimit
                } else {
                    maxIndex = filtered.count - 1
                }
                self.viewModel.moveDown(maxIndex: maxIndex)
                return nil // Consume event
                
            case 36: // Return/Enter
                if filtered.count > self.viewModel.displayedLimit && self.viewModel.selectionIndex == self.viewModel.displayedLimit {
                    // Load More clicked
                    self.viewModel.displayedLimit += self.viewModel.pageSize
                    return nil
                }
                
                if self.viewModel.selectionIndex >= 0 && self.viewModel.selectionIndex < filtered.count {
                    // Ensure we don't select hidden items
                    if self.viewModel.selectionIndex < self.viewModel.displayedLimit {
                        self.selectItem(filtered[self.viewModel.selectionIndex])
                    }
                }
                return nil // Consume event
                
            case 35: // Command+P for toggle pin
                if event.modifierFlags.contains(.command) {
                     // Check strictly less than displayedLimit so we don't try to pin the Load More button
                     if self.viewModel.selectionIndex >= 0 &&
                        self.viewModel.selectionIndex < filtered.count &&
                        self.viewModel.selectionIndex < self.viewModel.displayedLimit {
                        self.togglePin(filtered[self.viewModel.selectionIndex])
                        return nil
                    }
                }
                return event
                
            case 18, 19, 20, 21, 23, 22, 26, 28, 25: // 1-9 Keys
                if SettingsManager.shared.quickPasteEnabled && event.modifierFlags.contains(.command) {
                    // Map key code to index 0-8
                    // 18->0, 19->1, 20->2, 21->3, 23->4, 22->5, 26->6, 28->7, 25->8
                    var index: Int?
                    switch event.keyCode {
                    case 18: index = 0
                    case 19: index = 1
                    case 20: index = 2
                    case 21: index = 3
                    case 23: index = 4
                    case 22: index = 5
                    case 26: index = 6
                    case 28: index = 7
                    case 25: index = 8
                    default: break
                    }
                    
                    if let index = index, index < filtered.count {
                        self.selectItem(filtered[index])
                        return nil
                    }
                }
                return event
                
            case 51: // Delete/Backspace
                // Should only delete if not editing text field?
                // Actually backspace is needed for search bar.
                // We should only handle backspace as "Delete Item" if command is pressed or if search is empty?
                // Standard behavior for these apps: Cmd+Backspace to delete item, Backspace filters.
                // Or: Backspace deletes text, if text empty and item selected... maybe not.
                // User requirement: "delete entries with backspace works"
                // If we add search, backspace MUST edit text.
                // Let's change item deletion to Cmd+Backspace or Fn+Backspace (Suppr)
                // For now, let's let Backspace go through to the text field unless modifier is pressed.    
                if event.modifierFlags.contains(.command) {
                    if self.viewModel.selectionIndex >= 0 && self.viewModel.selectionIndex < filtered.count {
                        self.deleteItem(filtered[self.viewModel.selectionIndex])
                        return nil
                    }
                }
                 return event
                
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
        ClipboardManager.shared.deleteItem(item)
        
        // Re-calculate filtered list size to adjust selection if needed
        let filtered = self.filteredItems
        if viewModel.selectionIndex >= filtered.count && viewModel.selectionIndex > 0 {
            viewModel.selectionIndex -= 1
        }
    }
    
    private func togglePin(_ item: ClipboardItem) {
        ClipboardManager.shared.togglePin(item)
    }
    
    // MARK: - NSWindowDelegate
    func windowDidResignKey(_ notification: Notification) {
        if isVisible {
            hidePanel()
        }
    }
}
