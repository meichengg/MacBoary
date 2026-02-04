//
//  ClipboardPreviewView.swift
//  macboary
//
//  Created by Antigravity on 02/02/2026.
//

import SwiftUI

struct ClipboardPreviewView: View {
    let item: ClipboardItem?
    let searchText: String
    @ObservedObject var settingsManager = SettingsManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let item = item {
                        contentView(for: item)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        emptyStateView
                    }
                }
                .padding(20)
                .frame(minHeight: geometry.size.height, alignment: .topLeading)
            }
        }
        .background(Color.black.opacity(0.2))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.3))
            Text(settingsManager.localized("no_selection"))
                .foregroundColor(.secondary.opacity(0.5))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func contentView(for item: ClipboardItem) -> some View {
        switch item.type {
        case .text:
            textPreview(content: item.content)
        case .image:
            imagePreview(path: item.imagePath)
        case .file:
            filePreview(path: item.filePath, name: item.content)
        }
    }
    
    private func textPreview(content: String) -> some View {
        // Optimization: Limit preview content to avoid freezing on large text
        let limit = 5000
        let displayContent = content.count > limit ? String(content.prefix(limit)) + "\n... (Text truncated for performance)" : content
        
        return Group {
            if searchText.isEmpty {
                Text(displayContent)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            } else {
                highlightedText(content: displayContent, query: searchText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .textSelection(.enabled)
    }
    
    private func imagePreview(path: String?) -> some View {
        ImagePreviewContent(imagePath: path)
    }
    
    private func filePreview(path: String?, name: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                if let path = path {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                } else {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let path = path {
                        Text(path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            
            Divider()
            
            Text("File Info")
                .font(.headline)
                .foregroundColor(.secondary)
            
                if let path = path, let attr = try? FileManager.default.attributesOfItem(atPath: path) {
                VStack(alignment: .leading, spacing: 8) {
                    infoRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: attr[.size] as? Int64 ?? 0, countStyle: .file))
                    if let creation = attr[.creationDate] as? Date {
                         infoRow(label: "Created", value: creation.formatted(date: .numeric, time: .shortened))
                    }
                    if let modification = attr[.modificationDate] as? Date {
                        infoRow(label: "Modified", value: modification.formatted(date: .numeric, time: .shortened))
                    }
                }
            }
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.subheadline)
        }
    }
    
    // Using AttributedString for highlighting in SwiftUI
    private func highlightedText(content: String, query: String) -> Text {
        guard !content.isEmpty, !query.isEmpty else { return Text(content) }
        
        // Simpler approach: manual attributed string construction
        var finalString = AttributedString()
        let nsString = content as NSString
        let regex = try? NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: query), options: .caseInsensitive)
        
        var currentIndex = 0
        let matches = regex?.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in matches {
            // Text before match
            let rangeBefore = NSRange(location: currentIndex, length: match.range.location - currentIndex)
            if rangeBefore.length > 0 {
                finalString.append(AttributedString(nsString.substring(with: rangeBefore)))
            }
            
            // Match
            var highlightedPart = AttributedString(nsString.substring(with: match.range))
            highlightedPart.backgroundColor = .orange.opacity(0.8)
            highlightedPart.foregroundColor = .black
            finalString.append(highlightedPart)
            
            currentIndex = match.range.location + match.range.length
        }
        
        // Text after last match
        if currentIndex < nsString.length {
            let rangeAfter = NSRange(location: currentIndex, length: nsString.length - currentIndex)
            finalString.append(AttributedString(nsString.substring(with: rangeAfter)))
        }
        
        return Text(finalString)
    }
}

// Separate view for image preview with async loading
private struct ImagePreviewContent: View {
    let imagePath: String?
    @State private var image: NSImage?
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                    Text("Image not found")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: imagePath) { _, _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        isLoading = true
        image = nil
        
        Task { @MainActor in
            if let path = imagePath {
                image = ClipboardManager.shared.getImage(named: path)
            }
            isLoading = false
        }
    }
}
