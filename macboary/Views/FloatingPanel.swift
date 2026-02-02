//
//  FloatingPanel.swift
//  macboary
//
//  Created by Marco Baeuml on 24/01/2026.
//

import AppKit
import SwiftUI
import Combine
import Carbon

struct SendableEvent: @unchecked Sendable {
    let event: NSEvent
}

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
        self.isMovableByWindowBackground = true
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
@MainActor
class HistoryViewModel: ObservableObject {
    static let defaultPageSize = 20
    var pageSize: Int { Self.defaultPageSize }
    
    @Published var selectionIndex: Int = 0
    @Published var scrollToIndex: Int? = nil // Only used to trigger programmatic scrolling
    @Published var displayedLimit: Int = HistoryViewModel.defaultPageSize
    @Published var searchText: String = "" {
        didSet {
            if oldValue != searchText {
                // Debounce search processing
                searchTask?.cancel()
                searchTask = Task(priority: .userInitiated) {
                    // Very short delay to debounce fast typing but feel instant
                    try? await Task.sleep(nanoseconds: 50 * 1_000_000) // 50ms
                    if Task.isCancelled { return }
                    
                    await self.performSearch(query: searchText)
                }
            }
        }
    }
    
    // Published filtered items allow UI to bind directly
    @Published private(set) var filteredItems: [ClipboardItem] = []
    
    // Trigger to force focus on search field
    @Published var shouldFocusSearch = false
    
    private var searchTask: Task<Void, Error>?
    private var allItems: [ClipboardItem] = []
    
    init() {
        // Initial load - defer to Task to avoid isolation issues in init
        Task {
            self.updateItems(ClipboardManager.shared.items)
        }
    }
    
    func updateItems(_ items: [ClipboardItem]) {
        self.allItems = items
        // If not searching, just show all
        if searchText.isEmpty {
            self.filteredItems = items
        } else {
             Task { await performSearch(query: searchText) }
        }
    }
    
    private var lastQuery = ""
    
    private func performSearch(query: String) async {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 0. Smart Filters (Exact Match) - "Raycast-like" Commands
        var smartResults: [ClipboardItem]? = nil
        
        switch normalizedQuery {
        case "image", "images":
            smartResults = allItems.filter { $0.type == .image }
        case "file", "files":
             smartResults = allItems.filter { $0.type == .file }
        case "link", "links", "url", "urls":
             // Simple URL detection
             smartResults = allItems.filter { 
                 $0.type == .text && 
                 ($0.searchKey.contains("http://") || $0.searchKey.contains("https://") || $0.searchKey.contains("www.")) 
             }
        case "pin", "pinned", "pins":
             smartResults = allItems.filter { $0.isPinned }
        default:
            break
        }
        
        if let smart = smartResults {
            lastQuery = "" // Reset incremental optimization
            await MainActor.run {
                self.filteredItems = Array(smart.prefix(2500))
                self.selectionIndex = 0
                self.scrollToIndex = 0
                self.displayedLimit = self.pageSize
            }
            return
        }
        
        // 1. Incremental Search Optimization
        // If narrowing down (e.g. "te" -> "tes"), search within current results to save CPU
        let useIncremental = normalizedQuery.hasPrefix(lastQuery) && !lastQuery.isEmpty
        let sourceItems = useIncremental ? filteredItems : allItems
        
        lastQuery = normalizedQuery // Update for next time
        
        if query.isEmpty {
            await MainActor.run {
                self.filteredItems = self.allItems
                self.selectionIndex = 0
                self.scrollToIndex = 0 
                self.displayedLimit = self.pageSize
            }
            return
        }
        
        // 2. Offload to Background Thread (Detached Task)
        // This prevents Main Thread freeze/lag during typing
        let maxResults = 2500
        
        let results = await Task.detached(priority: .userInitiated) {
             return Array(sourceItems.lazy.filter { item in
                 return item.searchKey.contains(normalizedQuery)
             }.prefix(maxResults))
        }.value
        
        // 3. Update UI
        if !Task.isCancelled {
            await MainActor.run {
                self.filteredItems = results
                self.selectionIndex = 0
                self.scrollToIndex = 0
                self.displayedLimit = self.pageSize
            }
        }
    }
    
    func loadMore() {
        if displayedLimit < filteredItems.count {
            displayedLimit += pageSize
        }
    }
    
    func moveUp() {
        if selectionIndex > 0 {
            selectionIndex -= 1
            scrollToIndex = selectionIndex // Trigger scroll
        }
    }
    
    func moveDown(maxIndex: Int) {
        if selectionIndex < maxIndex {
            selectionIndex += 1
            scrollToIndex = selectionIndex // Trigger scroll
            
            // Auto load more if near end
            if selectionIndex >= displayedLimit - 2 {
                loadMore()
            }
        }
    }
    
    func reset() {
        selectionIndex = 0
        scrollToIndex = 0
        displayedLimit = pageSize
        searchText = ""
        // Reset items to full list immediately
        updateItems(ClipboardManager.shared.items)
    }
    
    func removeItem(_ item: ClipboardItem) {
        // Remove from persistent list copy
        allItems.removeAll { $0.id == item.id }
        
        // Remove from current view
        filteredItems.removeAll { $0.id == item.id }
        
        // Adjust selection if it was at the bottom
        if selectionIndex >= filteredItems.count && selectionIndex > 0 {
            selectionIndex = filteredItems.count - 1
        }
    }
    
    func togglePin(_ item: ClipboardItem) {
        // Helper to update and re-sort a list
        func updateList(_ list: inout [ClipboardItem]) {
            if let index = list.firstIndex(where: { $0.id == item.id }) {
                var updated = list[index]
                updated.isPinned.toggle()
                list.remove(at: index)
                
                if updated.isPinned {
                    list.insert(updated, at: 0)
                } else {
                    // Start of unpinned section
                    let pinnedCount = list.filter { $0.isPinned }.count
                    list.insert(updated, at: pinnedCount)
                }
            }
        }
        
        // update copy in allItems (Backend mirror)
        updateList(&allItems)
        
        // update filteredItems
        // If searching, we might not want to re-sort aggressively, but let's be consistent
        if searchText.isEmpty {
             updateList(&filteredItems)
        } else {
            // Just toggle property in place to avoid disrupting search result order too much
            if let index = filteredItems.firstIndex(where: { $0.id == item.id }) {
                filteredItems[index].isPinned.toggle()
            }
        }
    }
}

@MainActor
class FloatingPanelController: NSObject, NSWindowDelegate {
    static let shared = FloatingPanelController()
    
    private var panel: FloatingPanel?
    private var previousApp: NSRunningApplication?
    private var hostingView: NSHostingView<AnyView>?
    
    let viewModel = HistoryViewModel()
    var isVisible = false
    private var isReady = false // Gatekeeper for app startup
    
    private var eventMonitor: Any?
    private var keyMonitor: Any?
    
    private override init() {
        super.init()
    }
    
    // deinit removed as this is a singleton and deinit is non-isolated while class is MainActor
    // Accessing isolated properties in deinit causes errors and isn't needed for singleton lifecycle.
    
    @MainActor func setReady(_ ready: Bool) {
        self.isReady = ready
    }
    
    // Use ViewModel's filtered items instead of computing locally
    @MainActor private var filteredItems: [ClipboardItem] {
        return viewModel.filteredItems
    }
    
    @MainActor func showPanel() {
        // Don't show panel if app is not ready (setup in progress)
        if !isReady {
            print("App not ready yet, supressing showPanel")
            return
        }

        // Don't show panel while permission request is in progress
        if PermissionManager.shared.isRequestingPermission {
            return
        }
        
        // Store the currently active app before showing panel
        previousApp = NSWorkspace.shared.frontmostApplication
        
        // Sync items and reset
        viewModel.updateItems(ClipboardManager.shared.items)
        // viewModel.reset() // Removed to preserve scroll position as requested
        
        // Create panel if needed
        if panel == nil {
            createPanel()
        }
        
        // Position panel based on settings
        positionPanel()
        
        // Show panel and make it key
        panel?.orderFrontRegardless()
        panel?.makeKey()
        
        // Force focus on search field via ViewModel trigger
        viewModel.shouldFocusSearch.toggle()
        
        isVisible = true
        
        // Start monitoring for clicks outside and keyboard
        startEventMonitoring()
    }
    
    @MainActor private func createPanel() {
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 450))
        panel?.delegate = self
        
        let historyView = ClipboardHistoryView(
            viewModel: viewModel,
            onConfirm: { @MainActor [weak self] item in
                self?.confirmSelection(item)
            },
            onSelect: { @MainActor [weak self] item in
                self?.updateSelection(item)
            },
            onDelete: { @MainActor [weak self] item in
                self?.deleteItem(item)
            },
            onPin: { @MainActor [weak self] item in
                self?.togglePin(item)
            }
        )
        
        let wrappedView = AnyView(historyView)
        hostingView = NSHostingView(rootView: wrappedView)
        hostingView?.layer?.cornerRadius = 12
        hostingView?.layer?.masksToBounds = true
        
        panel?.contentView = hostingView
    }
    
    @MainActor func hidePanel() {
        stopEventMonitoring()
        panel?.orderOut(nil)
        isVisible = false
        
        // Restore focus to previous app (use targetApp captured by HotkeyManager before MacBoary activated)
        if let targetApp = PasteService.shared.targetApp, !targetApp.isTerminated {
            targetApp.activate()
        } else if let previousApp = previousApp, !previousApp.isTerminated {
            // Fallback to previousApp if targetApp not available
            previousApp.activate()
        }
    }
    
    @MainActor func togglePanel() {
        if isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }
    
    @MainActor private func positionPanel() {
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
            
            // Don't close if an alert is showing
            if panel.attachedSheet != nil { return }
            
            let mouseLocation = NSEvent.mouseLocation
            if !panel.frame.contains(mouseLocation) {
                Task { @MainActor in
                    self.hidePanel()
                }
            }
        }
        
        // Monitor for keyboard events - this intercepts at the app level
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isVisible else { return event }
            
            // If an alert/sheet is attached (e.g. Delete Confirmation), let it handle the keys (Enter/Esc)
            if self.panel?.attachedSheet != nil { return event }
            
            // Local monitor always runs on main thread, but compiler doesn't know event is safe to capture
            let sendableEvent = SendableEvent(event: event)
            
            return MainActor.assumeIsolated {
                self.handleKeyDown(sendableEvent.event)
            }
        }
            
        }


    @MainActor
    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        // Allow typing in search field (don't capture if it's a character key, unless modifiers)
        // Check for search field focus or similar if needed? 
        // For now, MacBoary logic was: capture arrows, enter, specific hotkeys, pass rest.
        
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
                    self.confirmSelection(filtered[self.viewModel.selectionIndex])
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
                    self.confirmSelection(filtered[index])
                    return nil
                }
            }
            return event
            
        case 51: // Delete/Backspace
            // Only capture Backspace if search text is empty, otherwise let it edit text
            if self.viewModel.searchText.isEmpty {
                 if self.viewModel.selectionIndex >= 0 && self.viewModel.selectionIndex < filtered.count {
                     self.deleteItem(filtered[self.viewModel.selectionIndex])
                     return nil
                 }
            }
             return event
             
        case 117: // Forward Delete
             // Forward delete typically deletes item in list context
             if self.viewModel.selectionIndex >= 0 && self.viewModel.selectionIndex < filtered.count {
                 self.deleteItem(filtered[self.viewModel.selectionIndex])
                 return nil
             }
             return event
            
        default:
            return event // Pass other keys through
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
    
    @MainActor private func confirmSelection(_ item: ClipboardItem) {
        ClipboardManager.shared.selectItem(item)
        hidePanel()
        
        // Activate previous app and paste, but check if it's still running
        if let previousApp = previousApp, !previousApp.isTerminated {
            previousApp.activate()
            PasteService.shared.pasteToFrontApp()
        }
    }
    
    @MainActor private func updateSelection(_ item: ClipboardItem) {
        // Find index of item in filtered list and update selectionIndex
        if let index = filteredItems.firstIndex(where: { $0.id == item.id }) {
            viewModel.selectionIndex = index
        }
    }
    
    @MainActor private func deleteItem(_ item: ClipboardItem) {
        guard let panel = self.panel else { return }
        
        let alert = NSAlert()
        alert.messageText = "Delete Item?"
        alert.informativeText = "Are you sure you want to delete this item from history? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: panel) { [weak self] response in
            guard let self = self, response == .alertFirstButtonReturn else { return }
            self.performDelete(item)
        }
    }
    
    @MainActor private func performDelete(_ item: ClipboardItem) {
        ClipboardManager.shared.deleteItem(item)
        
        // Update View Model immediately to reflect changes in UI
        viewModel.removeItem(item)
    }
    
    @MainActor private func togglePin(_ item: ClipboardItem) {
        ClipboardManager.shared.togglePin(item)
        
        // Update View Model immediately (Frontend consistency)
        viewModel.togglePin(item)
    }
    
    // MARK: - NSWindowDelegate
    func windowDidResignKey(_ notification: Notification) {
        // Don't hide if we have a modal sheet (like Delete Confirmation) attached
        if let panel = panel, panel.attachedSheet != nil {
            return
        }
        
        if isVisible {
            hidePanel()
        }
    }
}
