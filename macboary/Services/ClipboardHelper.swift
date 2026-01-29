//
//  ClipboardHelper.swift
//  macboary
//
//  Created for Concurrency Fixes
//

import AppKit
import ImageIO

/// Helper class for non-isolated operations to avoid blocking MainActor
class ClipboardHelper {
    
    /// Loads a thumbnail from disk without main actor isolation
    static func loadThumbnail(path: String, maxDimension: CGFloat = 200) -> CGImage? {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupport = urls.first else { return nil }
        
        // Match logic from ClipboardManager
        let imageDir = appSupport.appendingPathComponent("app.macboary/images")
        let fileURL = imageDir.appendingPathComponent(path)
        
        // Try to decrypt if encrypted
        if let encryptedData = try? Data(contentsOf: fileURL),
           let decryptedData = EncryptionService.shared.decryptData(encryptedData),
           let imageSource = CGImageSourceCreateWithData(decryptedData as CFData, nil) {
            
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimension
            ]
            
            return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
        }
        
        // Fallback to unencrypted
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return cgImage
    }
}
