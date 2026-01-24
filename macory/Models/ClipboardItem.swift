//
//  ClipboardItem.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    var isPinned: Bool
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
    }
    
    var displayText: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let singleLine = trimmed.replacingOccurrences(of: "\n", with: " ")
        if singleLine.count > 100 {
            return String(singleLine.prefix(100)) + "..."
        }
        return singleLine
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
