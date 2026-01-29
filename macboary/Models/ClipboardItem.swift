//
//  ClipboardItem.swift
//  macboary
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation

enum ClipboardType: String, Codable {
    case text
    case image
    case file
}

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    var isPinned: Bool
    var type: ClipboardType
    var imagePath: String?
    var filePath: String?
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), isPinned: Bool = false, type: ClipboardType = .text, imagePath: String? = nil, filePath: String? = nil) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.type = type
        self.imagePath = imagePath
        self.filePath = filePath
    }
    
    // Manual decoding to handle backward compatibility with existing data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        
        // New fields with defaults
        type = try container.decodeIfPresent(ClipboardType.self, forKey: .type) ?? .text
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        filePath = try container.decodeIfPresent(String.self, forKey: .filePath)
    }
    
    var displayText: String {
        switch type {
        case .text:
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            let singleLine = trimmed.replacingOccurrences(of: "\n", with: " ")
            if singleLine.count > 100 {
                return String(singleLine.prefix(100)) + "..."
            }
            return singleLine.isEmpty ? "Empty Text" : singleLine
        case .image:
            return "Image"
        case .file:
            // Content stores filename
            return content
        }
    }
    
    @MainActor var timeAgo: String {
        let diff = Date().timeIntervalSince(timestamp)
        let settings = SettingsManager.shared
        
        if diff < 60 {
            return settings.localized("just_now")
        } else if diff < 3600 {
            let minutes = Int(diff / 60)
            return String(format: settings.localized("min_ago"), minutes)
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            let key = hours == 1 ? "hour_ago" : "hours_ago"
            return String(format: settings.localized(key), hours)
        } else {
            let days = Int(diff / 86400)
            let key = days == 1 ? "day_ago" : "days_ago"
            return String(format: settings.localized(key), days)
        }
    }
}
