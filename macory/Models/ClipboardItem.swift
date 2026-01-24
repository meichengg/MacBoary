//
//  ClipboardItem.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation

enum ClipboardType: String, Codable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    var isPinned: Bool
    var type: ClipboardType
    var imagePath: String?
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), isPinned: Bool = false, type: ClipboardType = .text, imagePath: String? = nil) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.type = type
        self.imagePath = imagePath
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
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
