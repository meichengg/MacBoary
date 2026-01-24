//
//  ClipboardHistoryView.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @ObservedObject var viewModel: HistoryViewModel
    var onSelect: (ClipboardItem) -> Void
    var onDelete: (ClipboardItem) -> Void
    var onPin: (ClipboardItem) -> Void
    
    // Compute filtered items here to ensure view updates when manager updates
    var filteredItems: [ClipboardItem] {
        if viewModel.searchText.isEmpty {
            return clipboardManager.items
        }
        return clipboardManager.items.filter {
            $0.content.localizedCaseInsensitiveContains(viewModel.searchText)
        }
    }
    
    // Focus state for search field
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Search
            VStack(spacing: 8) {
                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search history...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .focused($isSearchFocused)
                        .onAppear {
                            // Auto focus when created
                            isSearchFocused = true
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Divider()
                        .frame(height: 16)
                    
                    Button(action: {
                        let includePinned = NSEvent.modifierFlags.contains(.option)
                        clipboardManager.clearHistory(includePinned: includePinned)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear All (Option+Click to include pinned)")
                    .disabled(clipboardManager.items.isEmpty)
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: viewModel.searchText.isEmpty ? "clipboard" : "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(viewModel.searchText.isEmpty ? "No clipboard history" : "No results found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if viewModel.searchText.isEmpty {
                        Text("Copy something to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear) // Transparent list background
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                ClipboardItemRow(
                                    item: item,
                                    isSelected: index == viewModel.selectionIndex,
                                    onSelect: { onSelect(item) },
                                    onDelete: { onDelete(item) },
                                    onPin: { onPin(item) }
                                )
                                .id(index) // Use index for scrolling
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                    }
                    .onChange(of: viewModel.selectionIndex) { _, newIndex in
                        if newIndex >= 0 && newIndex < filteredItems.count {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Text(viewModel.searchText.isEmpty ? "\(clipboardManager.items.count) items" : "\(filteredItems.count) results")
                Spacer()
                Text("↑↓ select  ⏎ paste  ⌘P pin  ⌘⌫ delete")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 400, height: 500)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
}

// Background blur effect
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void
    var onPin: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Type Icon
            ZStack {
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: item.isPinned ? "pin.fill" : "text.alignleft")
                    .font(.system(size: 12))
                    .foregroundColor(item.isPinned ? .yellow : (isSelected ? .white : .secondary))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayText)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(item.timeAgo)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
            }
            
            Spacer()
            
            if isHovered || isSelected || item.isPinned {
                HStack(spacing: 4) {
                    Button(action: onPin) {
                        Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(item.isPinned ? .yellow : (isSelected ? .white.opacity(0.8) : .secondary))
                            .padding(6)
                            .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin (⌘P)" : "Pin (⌘P)")
                    
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                            .padding(6)
                            .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Delete (⌘⌫)")
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.05) : Color.clear))
        )
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
        viewModel: HistoryViewModel(),
        onSelect: { _ in },
        onDelete: { _ in },
        onPin: { _ in }
    )
}
