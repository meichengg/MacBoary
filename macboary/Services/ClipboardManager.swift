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
import CoreImage

@MainActor
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var items: [ClipboardItem] = []
    
    private var timer: Timer?
    private var cleanupTimer: Timer?
    private var lastChangeCount: Int = 0
    private let storageKey = "clipboardHistory"
    
    // Thumbnail cache to persist across panel open/close
    private let thumbnailCache = NSCache<NSString, NSImage>()
    
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
    
    var imagesDirectory: URL {
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
        
        // Smart Compression: HEIC (High Efficiency) vs PNG
        var imageData: Data?
        
        if SettingsManager.shared.enableCompression {
                // HEIC Conversion using CIContext
            if let tiffData = image.tiffRepresentation, let ciImage = CIImage(data: tiffData) {
                    let context = CIContext()
                    // Create HEIC Data
                    // Note: modern macOS supports HEIC via CGImageDestination or CIContext.
                    // Fallback to simpler JPEG if HEIC is too complex to implement directly with NSBitmapImageRep in older SDKs.
                    // Actually, NSBitmapImageRep doesn't directly support .heif in older swift versions properties keys.
                    // Using .jpeg for now as "High Efficiency" fallback or try specific kUTTypeHEIC if available.
                    // But user wanted HEIC. Let's try to use the correct `NSBitmapImageRep` approach if possible or `CIContext`.
                    // `NSBitmapImageRep` supports .tiff, .bmp, .gif, .jpeg, .png, .jpeg2000. It does NOT support HEIC directly in `representation(using:)`.
                    
                    // START FIX: Use CIContext to write HEIC
                    if let _ = try? context.writeHEIFRepresentation(of: ciImage, to: fileURL, format: .RGBA8, colorSpace: ciImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!) {
                         // WRITE SUCCESS but we need DATA to encrypt.
                         // CIContext writes to URL. We want Data.
                         // context.heifRepresentation(of: ...) -> Data
                         if let heicData = context.heifRepresentation(of: ciImage, format: .RGBA8, colorSpace: ciImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!, options: [:]) {
                             imageData = heicData
                         }
                    }
                }
        }
        
        // Fallback to PNG if HEIC failed or disabled
        if imageData == nil {
            if let tiffData = image.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData) {
                imageData = bitmapImage.representation(using: .png, properties: [:])
            }
        }
        
        guard let finalData = imageData else {
            return nil
        }
        
        // Check image size limit (max 10MB to prevent memory issues)
        let maxImageSize = 10 * 1024 * 1024 // 10MB
        if finalData.count > maxImageSize {
            print("Image too large (\(finalData.count) bytes), skipping")
            return nil
        }
        
        // Encrypt the image data
        guard let encryptedData = EncryptionService.shared.encryptData(finalData) else {
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
    
    // MARK: - Thumbnail Cache
    
    func getCachedThumbnail(for path: String) -> NSImage? {
        return thumbnailCache.object(forKey: path as NSString)
    }
    
    func cacheThumbnail(_ image: NSImage, for path: String) {
        thumbnailCache.setObject(image, forKey: path as NSString)
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
        
        // Initial cleanup on launch
        Task { @MainActor in
            self.cleanupOldItems()
            self.cleanupDragTempFiles()
        }
        
        // Periodic cleanup timer (every hour)
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupOldItems()
                self?.cleanupDragTempFiles()
            }
        }
    }
    
    // Cleanup temporary files created for Drag & Drop
    private func cleanupDragTempFiles() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("MacBoaryDragTemp")
        
        // Check if exists
        if FileManager.default.fileExists(atPath: tempDir.path) {
            do {
                // Get all files
                let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey])
                
                // Delete files older than 1 hour (to avoid deleting file currently being dragged)
                // Or just delete everything on app launch, and conservative cleanup periodically.
                // Strategy: Delete files older than 5 minutes. Drag operation shouldn't take longer.
                
                let now = Date()
                for file in contents {
                    if let creation = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate,
                       now.timeIntervalSince(creation) > 300 { // 5 minutes
                        try? FileManager.default.removeItem(at: file)
                        print("🧹 Cleaned up temp drag file: \(file.lastPathComponent)")
                    }
                }
            } catch {
                print("⚠️ Failed to cleanup temp drag files: \(error)")
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
            
            // Delete associated images
            for item in itemsToDelete {
                if let imagePath = item.imagePath {
                    self.deleteImage(named: imagePath)
                }
            }
            
            // Save if any changes
            if !itemsToDelete.isEmpty {
                self.saveHistory()
            }
            
            // Enforce Size Limit
            self.enforceSizeLimit()
        }
    }
    
    private func enforceSizeLimit() {
        // Calculate total size using FileManager
        // (Implementation details similar to previous attempt)
        let historySize = (try? FileManager.default.attributesOfItem(atPath: historyFileURL.path)[.size] as? Int64) ?? 0
        
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupport = urls.first else { return }
        let imageDir = appSupport.appendingPathComponent("app.macboary/images")
        
        var imagesSize: Int64 = 0
        if let contents = try? FileManager.default.contentsOfDirectory(at: imageDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in contents {
                imagesSize += (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init) ?? 0) ?? 0
            }
        }
        
        let totalBytes = historySize + imagesSize
        let limitBytes = Int64(SettingsManager.shared.maxHistorySizeGB * 1024 * 1024 * 1024)
        
        if totalBytes > limitBytes {
            print("⚠️ Storage Limit Exceeded: \(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)) > \(ByteCountFormatter.string(fromByteCount: limitBytes, countStyle: .file))")
            
            // Sort by date ascending (oldest first)
            // Sort by date ascending (oldest first)
            let sortedItems = items.sorted { (item1: ClipboardItem, item2: ClipboardItem) -> Bool in
                return item1.timestamp < item2.timestamp
            }
            
            var bytesDeleted: Int64 = 0
            var itemsToDelete = [ClipboardItem]()
            
            for item in sortedItems {
                if item.isPinned { continue }
                
                let itemSize: Int64 = 1000 // approx metadata
                let imgSize: Int64 = item.imagePath != nil ? 500_000 : 0 // approx 500kb
                
                itemsToDelete.append(item)
                bytesDeleted += (itemSize + imgSize)
                
                if (totalBytes - bytesDeleted) < (limitBytes - 10_000_000) {
                    break
                }
            }
            
            if !itemsToDelete.isEmpty {
                 for item in itemsToDelete {
                     if let imagePath = item.imagePath {
                         self.deleteImage(named: imagePath)
                     }
                 }
                 self.items.removeAll { deletedItem in
                     itemsToDelete.contains { $0.id == deletedItem.id }
                 }
                 self.saveHistory()
                 print("🧹 Pruned \(itemsToDelete.count) items.")
            }
        }
    }

    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(items) else {
            NSLog("❌ CRITICAL: Failed to encode clipboard items")
            showCriticalError(SettingsManager.shared.localized("error_encode_history"))
            return
        }
        
        var dataToEncrypt = encoded
        
        // Smart Compression: LZFSE (Fast, Efficient) for text-heavy DB
        if SettingsManager.shared.enableCompression {
            do {
                let compressed = try (encoded as NSData).compressed(using: .lzfse) as Data
                dataToEncrypt = compressed
                print("📦 Database Compressed: \(encoded.count) -> \(compressed.count) bytes")
            } catch {
                print("⚠️ Compression failed, fallback to raw: \(error)")
            }
        }
        
        // Encrypt the data before storing
        guard let encryptedData = EncryptionService.shared.encryptData(dataToEncrypt) else {
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
           let decryptedData = EncryptionService.shared.decryptData(encryptedData) {
            
            // Attempt LZFSE Decompression (New Format)
            var jsonToDecode = decryptedData
            if SettingsManager.shared.enableCompression {
                do {
                    // Try to decompress. If data is not compressed LZFSE, this might throw or return garbage.
                    // However, NSData.decompressed(using:) usually throws if header invalid.
                    let decompressed = try (decryptedData as NSData).decompressed(using: .lzfse) as Data
                    jsonToDecode = decompressed
                    print("📦 Database Decompressed: \(decryptedData.count) -> \(decompressed.count) bytes")
                } catch {
                    // Not compressed or legacy format? Keep raw decrypted data.
                    // print("⚠️ Decompression failed (might be legacy uncompressed data): \(error)")
                }
            }
            
            if let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: jsonToDecode) {
                items = decoded
                return
            } else {
                // If decompression passed but decode failed (or decompression skipped), 
                // try decoding the original decrypted data (Legacy Fallback)
                if let legacyDecoded = try? JSONDecoder().decode([ClipboardItem].self, from: decryptedData) {
                    print("🔄 Loaded Legacy Uncompressed Database")
                    items = legacyDecoded
                    return
                }
            }
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
    
    // MARK: - Password Change Re-encryption
    
    /// Re-encrypt all data when password changes
    /// Call this BEFORE changing the password while old key is still active
    /// Returns decrypted image data keyed by path
    func prepareForPasswordChange() -> [String: Data] {
        var decryptedImages: [String: Data] = [:]
        
        // Decrypt all images with current key
        for item in items {
            if let path = item.imagePath {
                let fileURL = imagesDirectory.appendingPathComponent(path)
                if let encryptedData = try? Data(contentsOf: fileURL),
                   let decryptedData = EncryptionService.shared.decryptData(encryptedData) {
                    decryptedImages[path] = decryptedData
                }
            }
        }
        
        return decryptedImages
    }
    
    /// Complete password change by re-encrypting all data with new key
    /// Call this AFTER password has been changed to new key
    func completePasswordChange(decryptedImages: [String: Data]) {
        // Re-encrypt and save all images with new key
        for (path, imageData) in decryptedImages {
            let fileURL = imagesDirectory.appendingPathComponent(path)
            if let encryptedData = EncryptionService.shared.encryptData(imageData) {
                try? encryptedData.write(to: fileURL)
            }
        }
        
        // Re-save history with new key
        saveHistory()
    }
    
    // MARK: - Import/Export
    
    /// Export package structure: items + images data
    private struct ExportPackage: Codable {
        let items: [ClipboardItem]
        let images: [String: Data] // imagePath -> raw PNG data
    }
    
    /// Export data as encrypted blob for backup/transfer
    /// Images are decrypted and included so backup works across password changes
    func exportData() -> Data? {
        // Collect image data (decrypted)
        var imagesData: [String: Data] = [:]
        for item in items {
            if let path = item.imagePath {
                // Try to get decrypted image data
                let fileURL = imagesDirectory.appendingPathComponent(path)
                if let encryptedData = try? Data(contentsOf: fileURL),
                   let decryptedData = EncryptionService.shared.decryptData(encryptedData) {
                    imagesData[path] = decryptedData
                }
            }
        }
        
        // Create export package
        let package = ExportPackage(items: items, images: imagesData)
        
        // Encode to JSON
        guard let jsonData = try? JSONEncoder().encode(package) else {
            print("❌ Failed to encode export package")
            return nil
        }
        
        var dataToEncrypt = jsonData
        
        // Smart Compression for Export
        if SettingsManager.shared.enableCompression {
            do {
                let compressed = try (jsonData as NSData).compressed(using: .lzfse) as Data
                dataToEncrypt = compressed
                print("📦 Export Compressed: \(jsonData.count) -> \(compressed.count) bytes")
            } catch {
                print("⚠️ Export Compression failed: \(error)")
            }
        }
        
        // Encrypt with current password
        guard let encrypted = EncryptionService.shared.encryptData(dataToEncrypt) else {
            print("❌ Failed to encrypt data for export")
            return nil
        }
        
        // Create export file: salt + verifier + encrypted data
        var exportPackage = Data()
        
        // Include salt and verifier so import can use same password
        if let salt = UserDefaults.standard.data(forKey: "com.macboary.encryption.salt"),
           let verifier = UserDefaults.standard.data(forKey: "com.macboary.encryption.verifier") {
            // Format: [4 bytes salt length][salt][4 bytes verifier length][verifier][encrypted data]
            var saltLen = UInt32(salt.count)
            exportPackage.append(Data(bytes: &saltLen, count: 4))
            exportPackage.append(salt)
            
            var verifierLen = UInt32(verifier.count)
            exportPackage.append(Data(bytes: &verifierLen, count: 4))
            exportPackage.append(verifier)
        } else {
            // No encryption configured
            var zero: UInt32 = 0
            exportPackage.append(Data(bytes: &zero, count: 4))
            exportPackage.append(Data(bytes: &zero, count: 4))
        }
        
        exportPackage.append(encrypted)
        return exportPackage
    }
    
    /// Import data from backup, requires the password used during export
    func importData(_ data: Data, password: String) -> Bool {
        guard data.count > 8 else { return false }
        
        var offset = 0
        
        // Read salt length
        let saltLen = data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: UInt32.self) }
        offset += 4
        
        var importedSalt: Data?
        
        if saltLen > 0 {
            // Read salt
            let salt = data.subdata(in: offset..<(offset+Int(saltLen)))
            offset += Int(saltLen)
            importedSalt = salt
            
            // Read verifier length
            let verifierLen = data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: UInt32.self) }
            offset += 4
            
            // Read verifier (skip it for now, we'll verify by successful decryption)
            offset += Int(verifierLen)
        } else {
            offset += 4 // Skip verifier length
        }
        
        // Remaining is encrypted data
        let encryptedData = data.subdata(in: offset..<data.count)
        
        // Decrypt with provided password and imported salt
        let decrypted: Data?
        if let salt = importedSalt {
            // Decrypt using the backup's salt + user-provided password
            decrypted = EncryptionService.shared.decryptDataWithCredentials(
                password: password,
                salt: salt,
                encryptedData: encryptedData
            )
        } else {
            // No encryption in backup, try current key or treat as plain data
            decrypted = EncryptionService.shared.decryptData(encryptedData)
        }
        
        guard let decryptedData = decrypted else {
            print("❌ Failed to decrypt imported data - wrong password?")
            return false
        }
        
        // Smart Decompression for Import
        // Try LZFSE first (New format)
        var jsonToDecode = decryptedData
        if SettingsManager.shared.enableCompression {
             do {
                 let decompressed = try (decryptedData as NSData).decompressed(using: .lzfse) as Data
                 jsonToDecode = decompressed
                 print("📦 Import Decompressed: \(decryptedData.count) -> \(decompressed.count) bytes")
             } catch {
                 // Might be uncompressed legacy backup
             }
        }
        
        // Try to decode as new ExportPackage format (with images)
        var decodedItems: [ClipboardItem] = []
        var importedImages: [String: Data] = [:]
        
        if let package = try? JSONDecoder().decode(ExportPackage.self, from: jsonToDecode) {
            decodedItems = package.items
            importedImages = package.images
        } else if let package = try? JSONDecoder().decode(ExportPackage.self, from: decryptedData) {
            // Fallback: Try decoding raw decrypted data (if decompression skipped or failed but manual logic above missed it)
            decodedItems = package.items
            importedImages = package.images
        } else {
             // Fallback: Legacy format (Array of Items only)
             if let items = try? JSONDecoder().decode([ClipboardItem].self, from: jsonToDecode) {
                 decodedItems = items
             } else if let items = try? JSONDecoder().decode([ClipboardItem].self, from: decryptedData) {
                 decodedItems = items
             }
        }
        
        if decodedItems.isEmpty {
            // Decoding failed for all formats
            print("❌ Failed to decode imported data (or empty backup)")
            return false
        }
        
        // MERGE: Add imported items that don't already exist (by ID)
        let existingIDs = Set(items.map { $0.id })
        let newItems = decodedItems.filter { !existingIDs.contains($0.id) }
        
        // Re-encrypt and save imported images with CURRENT key
        for (imagePath, imageData) in importedImages {
            // Only save if this image belongs to an item being imported
            if newItems.contains(where: { $0.imagePath == imagePath }) {
                let fileURL = imagesDirectory.appendingPathComponent(imagePath)
                
                // Encrypt with current key and save
                if let encryptedData = EncryptionService.shared.encryptData(imageData) {
                    try? encryptedData.write(to: fileURL)
                }
            }
        }
        
        // Add new items to list
        items.insert(contentsOf: newItems, at: 0)
        
        // Re-sort: pinned first, then by timestamp
        items.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            return lhs.timestamp > rhs.timestamp
        }
        
        saveHistory()
        
        return true
    }
}
