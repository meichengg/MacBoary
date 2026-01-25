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
        cleanupOldItems()
        startMonitoring()
    }
    
    // MARK: - Image Storage
    
    private var imagesDirectory: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls[0].appendingPathComponent("app.macory/images")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport
    }
    
    private func saveImage(_ image: NSImage) -> String? {
        let fileName = UUID().uuidString + ".png"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        do {
            try pngData.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    func getImage(named name: String) -> NSImage? {
        let fileURL = imagesDirectory.appendingPathComponent(name)
        return NSImage(contentsOf: fileURL)
    }
    
    private func deleteImage(named name: String) {
        let fileURL = imagesDirectory.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: fileURL)
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
        
        // 1. Check for Image
        // Prioritize explicit image types to avoid catching icons from files/text
        let types = pasteboard.types ?? []
        var isImageCandidate = false
        
        // Case A: Direct image data (e.g. screenshot, specialized copy)
        if (types.contains(.tiff) || types.contains(.png)) && !types.contains(.fileURL) {
            isImageCandidate = true
        }
        // Case B: File URL that points to an image (e.g. Telegram, Finder image copy)
        else if types.contains(.fileURL) {
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
               let url = urls.first {
                let imageExtensions = ["jpg", "jpeg", "png", "tiff", "tif", "gif", "heic", "bmp", "webp"]
                if imageExtensions.contains(url.pathExtension.lowercased()) {
                    isImageCandidate = true
                }
            }
        }
        
        if isImageCandidate {
            // Check if image storage is enabled
            if SettingsManager.shared.storeImages {
                if let image = NSImage(pasteboard: pasteboard) {
                    if let filename = saveImage(image) {
                         let newItem = ClipboardItem(content: "Image", type: .image, imagePath: filename)
                         add(newItem)
                         return
                    }
                }
            } else {
                // If images are disabled, do we skip or just ignore?
                // If we return here, we might miss text that is also available.
                // But usually if it's an image copy, primary type is image. 
                // Let's allow falling through to text check if image storage is disabled 
                // BUT only if there is text?
                // Actually, if I copy an image, I don't want to save "Image" text if I disallowed images.
            }
        }
        
        // 2. Check for Text
        guard let content = pasteboard.string(forType: .string),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let newItem = ClipboardItem(content: content)
        add(newItem)
    }
    
    private func add(_ newItem: ClipboardItem) {
        // Handle duplication for Text
        if newItem.type == .text {
            // Don't add duplicates at the top
            if let firstItem = items.first, firstItem.type == .text, firstItem.content == newItem.content {
                return
            }
            // Remove existing duplicate if present
            items.removeAll { $0.type == .text && $0.content == newItem.content }
        } else {
            // For images, hard to deduplicate efficiently without hash.
            // For now, accept duplicates or check naive comparison (not easy).
            // We just add it.
        }
        
        // Add new item at the top (after pinned items)
        let pinnedCount = items.filter { $0.isPinned }.count
        items.insert(newItem, at: pinnedCount)
        
        enforceLimit()
        saveHistory()
    }
    
    private func enforceLimit() {
        if items.count > maxItems {
             // Remove last item that is NOT pinned
             if let lastUnpinnedIndex = items.lastIndex(where: { !$0.isPinned }) {
                 let itemToRemove = items[lastUnpinnedIndex]
                 if let imagePath = itemToRemove.imagePath {
                     deleteImage(named: imagePath)
                 }
                 items.remove(at: lastUnpinnedIndex)
             } else {
                 items = Array(items.prefix(maxItems))
             }
        }
    }
    
    func selectItem(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if item.type == .image, let imagePath = item.imagePath, let image = getImage(named: imagePath) {
             pasteboard.writeObjects([image])
        } else {
             pasteboard.setString(item.content, forType: .string)
        }
        lastChangeCount = pasteboard.changeCount
        
        // If unpinned, move to top of unpinned section
        if !item.isPinned {
            items.removeAll { $0.id == item.id }
            let pinnedCount = items.filter { $0.isPinned }.count
            // Create new item with fresh timestamp (reuse image file for now, or copy?)
            // We reuse the image file.
            let refreshedItem = ClipboardItem(id: item.id, content: item.content, timestamp: Date(), isPinned: false, type: item.type, imagePath: item.imagePath)
            items.insert(refreshedItem, at: pinnedCount)
            saveHistory()
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let imagePath = item.imagePath {
            deleteImage(named: imagePath)
        }
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
                items.insert(updatedItem, at: 0)
            } else {
                let pinnedCount = items.filter { $0.isPinned }.count
                items.insert(updatedItem, at: pinnedCount)
            }
            saveHistory()
        }
    }
    
    func clearHistory(includePinned: Bool = false) {
        // Collect files to delete
        let itemsToDelete = includePinned ? items : items.filter { !$0.isPinned }
        
        for item in itemsToDelete {
            if let imagePath = item.imagePath {
                deleteImage(named: imagePath)
            }
        }
        
        if includePinned {
            items.removeAll()
        } else {
            items.removeAll { !$0.isPinned }
        }
        saveHistory()
    }
    
    private func cleanupOldItems() {
        let textDays = SettingsManager.shared.textRetentionDays
        let imageDays = SettingsManager.shared.imageRetentionDays
        
        let now = Date()
        let textCutoff = Calendar.current.date(byAdding: .day, value: -textDays, to: now) ?? now
        let imageCutoff = Calendar.current.date(byAdding: .day, value: -imageDays, to: now) ?? now
        
        var itemsToDelete: [ClipboardItem] = []
        
        items.removeAll { item in
            if item.isPinned { return false }
            
            let cutoff = item.type == .image ? imageCutoff : textCutoff
            if item.timestamp < cutoff {
                itemsToDelete.append(item)
                return true
            }
            return false
        }
        
        for item in itemsToDelete {
            if let imagePath = item.imagePath {
                deleteImage(named: imagePath)
            }
        }
        
        if !itemsToDelete.isEmpty {
            saveHistory()
        }
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
