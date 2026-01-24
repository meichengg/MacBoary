//
//  ClipboardManager.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation
import AppKit
import Combine

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var items: [ClipboardItem] = []
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let maxItems = 50
    private let storageKey = "clipboardHistory"
    
    private init() {
        loadHistory()
        startMonitoring()
    }
    
    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        guard let content = pasteboard.string(forType: .string),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Don't add duplicates at the top
        if let firstItem = items.first, firstItem.content == content {
            return
        }
        
        // Remove existing duplicate if present
        items.removeAll { $0.content == content }
        
        // Add new item at the top (after pinned items)
        let newItem = ClipboardItem(content: content)
        
        // Find split between pinned and unpinned
        let pinnedCount = items.filter { $0.isPinned }.count
        items.insert(newItem, at: pinnedCount)
        
        // Limit history size (excluding pinned items to prevent them from being pushed out?)
        // Or just limit total size? Let's limit unpinned size effectively.
        // Actually simplest is limit total size but pinned items are immune to deletion?
        // Let's just limit total items for now, but ensure we don't drop pinned items if possible.
        // Better strategy: Sort items so pinned are first, then chronological.
        
        if items.count > maxItems {
             // Remove last item that is NOT pinned
             if let lastUnpinnedIndex = items.lastIndex(where: { !$0.isPinned }) {
                 items.remove(at: lastUnpinnedIndex)
             } else {
                 // All items are pinned and we are over limit? Just trim the end
                 items = Array(items.prefix(maxItems))
             }
        }
        
        saveHistory()
    }
    
    func selectItem(_ item: ClipboardItem) {
        // Move item to top (respecting pins)
        if !item.isPinned {
            items.removeAll { $0.id == item.id }
            let pinnedCount = items.filter { $0.isPinned }.count
            items.insert(item, at: pinnedCount)
        }
        // If pinned, it stays where it is (sorted by pin then date usually, but here we just keep position or ensure top of pins?)
        // For pinned items, maybe we don't move them on selection? Or move to top of pinned list?
        // Let's keep it simple: Selection copies to clipboard. Re-ordering of unpinned happens automatically by checkClipboard detection.
        // But checkClipboard won't trigger if content matches recent.
        // So we should manually update the "freshness" or let checkClipboard handle it.
        // If we force copy to pasteboard, checkClipboard catches it.
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        lastChangeCount = pasteboard.changeCount
        
        // If unpinned, move to top of unpinned section
        if !item.isPinned {
            items.removeAll { $0.id == item.id }
            let pinnedCount = items.filter { $0.isPinned }.count
            // Create new item with fresh timestamp
            let refreshedItem = ClipboardItem(id: item.id, content: item.content, timestamp: Date(), isPinned: false)
            items.insert(refreshedItem, at: pinnedCount)
            saveHistory()
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    func togglePin(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = items[index]
            updatedItem.isPinned.toggle()
            items.remove(at: index)
            
            // Re-insert based on new pin state
            if updatedItem.isPinned {
                // Insert at top of list (beginning of pinned items)
                items.insert(updatedItem, at: 0)
            } else {
                // Insert at top of unpinned list (after all pinned items)
                // Or restore to chronological position?
                // Simplest is top of unpinned items (most recent unpinned)
                let pinnedCount = items.filter { $0.isPinned }.count
                items.insert(updatedItem, at: pinnedCount)
            }
            saveHistory()
        }
    }
    
    func clearHistory(includePinned: Bool = false) {
        if includePinned {
            items.removeAll()
        } else {
            items.removeAll { !$0.isPinned }
        }
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
        }
    }
}
