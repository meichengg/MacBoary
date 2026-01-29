//
//  ClipboardManager.swift
//  macboary
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation
import AppKit
import Combine
import ImageIO

@MainActor
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var items: [ClipboardItem] = []
    
    private var timer: Timer?
    private var cleanupTimer: Timer?
    private var lastChangeCount: Int = 0
    private let storageKey = "clipboardHistory"
    
    private var historyFileURL: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupport = urls.first else {
            let tempDir = FileManager.default.temporaryDirectory
            return tempDir.appendingPathComponent("macboary/history.enc")
        }
        let dir = appSupport.appendingPathComponent("app.macboary")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.enc")
    }
    
    private init() {
        loadHistory()
        cleanupOldItems()
        cleanupOrphanedImages()
        startMonitoring()
    }
    
    // MARK: - Image Storage
    
    private var imagesDirectory: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupport = urls.first else {
            // Fallback to temporary directory if application support is not available
            let tempDir = FileManager.default.temporaryDirectory
            return tempDir.appendingPathComponent("macboary/images")
        }
        let imageDir = appSupport.appendingPathComponent("app.macboary/images")
        try? FileManager.default.createDirectory(at: imageDir, withIntermediateDirectories: true)
        return imageDir
    }
    
    private func saveImage(_ image: NSImage) -> String? {
        let fileName = "\(UUID().uuidString).enc"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        // Check image size limit (max 10MB to prevent memory issues)
        let maxImageSize = 10 * 1024 * 1024 // 10MB
        if pngData.count > maxImageSize {
            print("Image too large (\(pngData.count) bytes), skipping")
            return nil
        }
        
        // Encrypt the image data
        guard let encryptedData = EncryptionService.shared.encryptData(pngData) else {
            print("Failed to encrypt image")
            return nil
        }
        
        do {
            try encryptedData.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    func getImage(named name: String) -> NSImage? {
        let fileURL = imagesDirectory.appendingPathComponent(name)
        
        // Try to load as encrypted file first
        if let encryptedData = try? Data(contentsOf: fileURL),
           let decryptedData = EncryptionService.shared.decryptData(encryptedData) {
            return NSImage(data: decryptedData)
        }
        
        // Fallback to unencrypted (for backward compatibility)
        return NSImage(contentsOf: fileURL)
    }
    
    func getThumbnail(named name: String, maxDimension: CGFloat = 200) -> NSImage? {
        // IMPORTANT: This method performs I/O and decryption operations.
        // It should ALWAYS be called from a background thread.
        // See ClipboardHistoryView.swift ClipboardItemRow.onAppear for correct usage.
        
        let fileURL = imagesDirectory.appendingPathComponent(name)
        
        // Try to decrypt if encrypted
        if let encryptedData = try? Data(contentsOf: fileURL),
           let decryptedData = EncryptionService.shared.decryptData(encryptedData),
           let imageSource = CGImageSourceCreateWithData(decryptedData as CFData, nil) {
            
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimension
            ]
            
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                return nil
            }
            
            return NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
        }
        
        // Fallback to unencrypted (for backward compatibility)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
    }
    
    private func deleteImage(named name: String) {
        let fileURL = imagesDirectory.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        
        // Main polling timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
        
        // Periodic cleanup timer (every hour)
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupOldItems()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        cleanupTimer?.invalidate()
        cleanupTimer = nil
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
            if SettingsManager.shared.imageRetentionDays != 0 {
                if let image = NSImage(pasteboard: pasteboard) {
                    if let filename = saveImage(image) {
                         let newItem = ClipboardItem(content: "Image", type: .image, imagePath: filename)
                         add(newItem)
                         return
                    }
                }
            }
        }
        
        // 2. Check for File (New)
        if types.contains(.fileURL) {
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
               let url = urls.first {
                // If we reached here, it wasn't processed as an image (or image storage disabled/failed).
                // So we treat it as a generic file.
                
                let filename = url.lastPathComponent
                let newItem = ClipboardItem(content: filename, type: .file, filePath: url.path)
                add(newItem)
                return
            }
        }
        
        // 2. Check for Text
        if SettingsManager.shared.textRetentionDays != 0 {
            guard let content = pasteboard.string(forType: .string),
                  !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            
            let newItem = ClipboardItem(content: content)
            add(newItem)
        }
    }
    
    private func add(_ newItem: ClipboardItem) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Handle duplication for Text and Files
            if newItem.type == .text {
                // Don't add duplicates at the top
                if let firstItem = self.items.first, firstItem.type == .text, firstItem.content == newItem.content {
                    return
                }
                // Remove existing duplicate if present
                self.items.removeAll { $0.type == .text && $0.content == newItem.content }
            } else if newItem.type == .file {
                 // Don't add duplicate files at top
                 if let firstItem = self.items.first, firstItem.type == .file, firstItem.filePath == newItem.filePath {
                     return
                 }
                 // Remove existing duplicate file
                 self.items.removeAll { $0.type == .file && $0.filePath == newItem.filePath }
            }
            
            // Add new item at the top (after pinned items)
            let pinnedCount = self.items.filter { $0.isPinned }.count
            self.items.insert(newItem, at: pinnedCount)
            
            self.enforceLimit()
            self.saveHistory()
        }
    }
    
    private func enforceLimit() {
        let maxItems = SettingsManager.shared.maxHistoryItems
        
        while items.count > maxItems {
            // Remove last item that is NOT pinned
            if let lastUnpinnedIndex = items.lastIndex(where: { !$0.isPinned }) {
                let itemToRemove = items[lastUnpinnedIndex]
                if let imagePath = itemToRemove.imagePath {
                    deleteImage(named: imagePath)
                }
                items.remove(at: lastUnpinnedIndex)
            } else {
                // Only pinned items remain. We allow exceeding the limit if they are all pinned.
                break
            }
        }
    }
    
    func selectItem(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if item.type == .image, let imagePath = item.imagePath, let image = getImage(named: imagePath) {
             pasteboard.writeObjects([image])
        } else if item.type == .file, let filePath = item.filePath {
             let url = URL(fileURLWithPath: filePath)
             pasteboard.writeObjects([url as NSURL])
        } else {
             pasteboard.setString(item.content, forType: .string)
        }
        
        let newChangeCount = pasteboard.changeCount
        
        // Update lastChangeCount and items on MainActor to prevent race condition
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.lastChangeCount = newChangeCount
            
            // If unpinned, move to top of unpinned section
            if !item.isPinned {
                self.items.removeAll { $0.id == item.id }
                let pinnedCount = self.items.filter { $0.isPinned }.count
                // Create new item with fresh timestamp (reuse image file for now, or copy?)
                // We reuse the image file.
                // We reuse the image file.
                let refreshedItem = ClipboardItem(
                    id: item.id,
                    content: item.content,
                    timestamp: Date(),
                    isPinned: false,
                    type: item.type,
                    imagePath: item.imagePath,
                    filePath: item.filePath
                )
                self.items.insert(refreshedItem, at: pinnedCount)
                self.saveHistory()
            }
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let imagePath = item.imagePath {
            deleteImage(named: imagePath)
        }
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.items.removeAll { $0.id == item.id }
            self.saveHistory()
        }
    }
    
    func togglePin(_ item: ClipboardItem) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                var updatedItem = self.items[index]
                updatedItem.isPinned.toggle()
                self.items.remove(at: index)
                
                // Re-insert based on new pin state
                if updatedItem.isPinned {
                    self.items.insert(updatedItem, at: 0)
                } else {
                    let pinnedCount = self.items.filter { $0.isPinned }.count
                    self.items.insert(updatedItem, at: pinnedCount)
                }
                
                self.saveHistory()
            }
        }
    }
    
    func clearHistory(includePinned: Bool = false) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Collect files to delete
            let itemsToDelete = includePinned ? self.items : self.items.filter { !$0.isPinned }
            
            for item in itemsToDelete {
                if let imagePath = item.imagePath {
                    self.deleteImage(named: imagePath)
                }
            }
            
            if includePinned {
                self.items.removeAll()
            } else {
                self.items.removeAll { !$0.isPinned }
            }
            
            self.saveHistory()
        }
    }
    
    private func cleanupOldItems() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            let textDays = SettingsManager.shared.textRetentionDays
            let imageDays = SettingsManager.shared.imageRetentionDays
            
            // If retention is "Forever" (-1), skip cleanup for that type
            // If retention is "Disabled" (0), cleanup everything of that type (which logic below handles: cuttoff = now)
            
            let now = Date()
            let textCutoff = textDays == -1 ? Date.distantPast : (Calendar.current.date(byAdding: .day, value: -textDays, to: now) ?? now)
            let imageCutoff = imageDays == -1 ? Date.distantPast : (Calendar.current.date(byAdding: .day, value: -imageDays, to: now) ?? now)
            
            var itemsToDelete: [ClipboardItem] = []
            
            self.items.removeAll { item in
                if item.isPinned { return false }
                
                let cutoff = item.type == .image ? imageCutoff : textCutoff // Files use text retention for now
                if item.timestamp < cutoff {
                    itemsToDelete.append(item)
                    return true
                }
                return false
            }
            
            for item in itemsToDelete {
                if let imagePath = item.imagePath {
                    self.deleteImage(named: imagePath)
                }
            }
            
            if !itemsToDelete.isEmpty {
                self.saveHistory()
            }
        }
    }

    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(items) else {
            NSLog("❌ CRITICAL: Failed to encode clipboard items")
            showCriticalError(SettingsManager.shared.localized("error_encode_history"))
            return
        }
        
        // Encrypt the data before storing
        guard let encryptedData = EncryptionService.shared.encryptData(encoded) else {
            NSLog("❌ CRITICAL: Failed to encrypt clipboard history. Data not saved. Check keychain access.")
            
            // Show user-facing error
            print("Failed to encrypt clipboard data. History not saved.")
            showCriticalError(SettingsManager.shared.localized("error_encrypt_history"))
            
            // Fallback: save unencrypted with warning if encryption is disabled
            if !UserDefaults.standard.bool(forKey: "encryptionEnabled") {
                do {
                    try encoded.write(to: historyFileURL, options: [.atomic, .completeFileProtection])
                } catch {
                    NSLog("❌ CRITICAL: Failed to save clipboard history even unencrypted: \(error)")
                }
            }
            return
        }
        
        do {
            try encryptedData.write(to: historyFileURL, options: [.atomic, .completeFileProtection])
        } catch {
            NSLog("❌ CRITICAL: Failed to save clipboard history: \(error)")
            showCriticalError("\(SettingsManager.shared.localized("error_save_history")): \(error.localizedDescription)")
        }
    }
    
    private func showCriticalError(_ message: String) {
        Task { @MainActor in
            let alert = NSAlert()
            alert.messageText = SettingsManager.shared.localized("error_clipboard_manager")
            alert.informativeText = message
            alert.alertStyle = .critical
            alert.addButton(withTitle: SettingsManager.shared.localized("ok"))
            alert.runModal()
        }
    }
    
    private func loadHistory() {
        // Try to load from secure file storage first
        if let encryptedData = try? Data(contentsOf: historyFileURL),
           let decryptedData = EncryptionService.shared.decryptData(encryptedData),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: decryptedData) {
            items = decoded
            return
        }
        
        // Fallback to UserDefaults for migration (old format)
        if let encryptedString = UserDefaults.standard.string(forKey: storageKey),
           let decryptedString = EncryptionService.shared.decrypt(encryptedString),
           let data = Data(base64Encoded: decryptedString),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
            // Migrate to new storage format
            saveHistory()
            // Remove from UserDefaults
            UserDefaults.standard.removeObject(forKey: storageKey)
            return
        }
        
        // Fallback to unencrypted data in UserDefaults (oldest format)
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
            // Migrate to new storage format with encryption
            saveHistory()
            // Remove from UserDefaults
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }
    
    private func cleanupOrphanedImages() {
        let validImagePaths = Set(items.compactMap { $0.imagePath })
        let imageDir = imagesDirectory
        
        Task.detached {
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: imageDir.path) else { return }
            
            for file in files where !validImagePaths.contains(file) {
                let fileURL = imageDir.appendingPathComponent(file)
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
}
