//
//  ClipboardHistoryView.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @ObservedObject var selectionState: SelectionState
    var onSelect: (ClipboardItem) -> Void
    var onDelete: (ClipboardItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .foregroundColor(.secondary)
                Text("Clipboard History")
                    .font(.headline)
                Spacer()
                Text("\(clipboardManager.items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if clipboardManager.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No clipboard history")
                        .foregroundColor(.secondary)
                    Text("Copy something to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(Array(clipboardManager.items.enumerated()), id: \.element.id) { index, item in
                                ClipboardItemRow(
                                    item: item,
                                    isSelected: index == selectionState.index,
                                    onSelect: { onSelect(item) },
                                    onDelete: { onDelete(item) }
                                )
                                .id(item.id) // Use item.id for proper view identity
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: selectionState.index) { _, newIndex in
                        if newIndex >= 0 && newIndex < clipboardManager.items.count {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                proxy.scrollTo(clipboardManager.items[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("↑↓ Navigate")
                Text("⏎ Paste")
                Text("⌫ Delete")
                Text("⎋ Close")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 400, height: 450)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayText)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(item.timeAgo)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
            }
            
            Spacer()
            
            if isHovered || isSelected {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.1) : Color.clear))
        )
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    ClipboardHistoryView(
        selectionState: SelectionState(),
        onSelect: { _ in },
        onDelete: { _ in }
    )
}
