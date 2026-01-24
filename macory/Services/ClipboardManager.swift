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
        
        // Add new item at the top
        let newItem = ClipboardItem(content: content)
        items.insert(newItem, at: 0)
        
        // Limit history size
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        
        saveHistory()
    }
    
    func selectItem(_ item: ClipboardItem) {
        // Move item to top of history
        items.removeAll { $0.id == item.id }
        items.insert(item, at: 0)
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        lastChangeCount = pasteboard.changeCount
        
        saveHistory()
    }
    
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    func clearHistory() {
        items.removeAll()
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
