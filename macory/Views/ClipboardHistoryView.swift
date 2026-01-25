//
//  ClipboardHistoryView.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @ObservedObject var settingsManager = SettingsManager.shared
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
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    TextField(settingsManager.localized("search_placeholder"), text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
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
                    
                    if !clipboardManager.items.isEmpty {
                        Divider()
                            .frame(height: 16)
                            .padding(.horizontal, 4)
                        
                        Button(action: {
                            let includePinned = NSEvent.modifierFlags.contains(.option)
                            clipboardManager.clearHistory(includePinned: includePinned)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(settingsManager.localized("clear_all"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(settingsManager.useCustomColors ? settingsManager.customSecondaryColor.color.opacity(0.3) : .clear)
            }
            
            Divider()
                .opacity(0.4)
            
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: viewModel.searchText.isEmpty ? "clipboard" : "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(viewModel.searchText.isEmpty ? settingsManager.localized("no_history") : settingsManager.localized("no_results"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if viewModel.searchText.isEmpty {
                        Text(settingsManager.localized("copy_start"))
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
                                    index: index,
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
            
            // Footer
            HStack {
                Text(viewModel.searchText.isEmpty ? String(format: settingsManager.localized("items_count"), clipboardManager.items.count) : String(format: settingsManager.localized("results_count"), filteredItems.count))
                Spacer()
                Text(settingsManager.localized("footer_help"))
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(settingsManager.useCustomColors ? settingsManager.customSecondaryColor.color.opacity(0.2) : .clear)
        }
        .frame(width: 400, height: 500)
        .background(
            Group {
                if settingsManager.useCustomColors {
                    settingsManager.customBackgroundColor.color
                } else {
                    VisualEffectView(material: .popover, blendingMode: .behindWindow)
                }
            }
        )
        .preferredColorScheme(settingsManager.appTheme.colorScheme)
        .tint(settingsManager.useCustomColors ? settingsManager.customAccentColor.color : nil)
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
    @ObservedObject var settingsManager = SettingsManager.shared
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void
    var onPin: () -> Void
    
    @State private var isHovered = false
    @State private var thumbnail: NSImage?
    
    var body: some View {
        HStack(spacing: 10) {
            // Type Icon
            ZStack {
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                let iconName: String = {
                    if item.isPinned { return "pin.fill" }
                    if item.type == .image { return "photo" }
                    return "text.alignleft"
                }()
                
                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundColor(item.isPinned ? .yellow : (isSelected ? .white : .secondary))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                if item.type == .image {
                    if let thumb = thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 60)
                            .cornerRadius(4)
                    } else {
                        // Placeholder or loading
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text(settingsManager.localized("loading_image"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 40)
                    }
                } else {
                    Text(item.displayText)
                        .font(.system(size: 13, weight: .regular))
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text(item.timeAgo)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
            }
            
            Spacer()
            
            // Shortcut Hint (⌘1-9)
            if settingsManager.quickPasteEnabled && index < 9 {
                Text("⌘\(index + 1)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary.opacity(0.5))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? Color.white.opacity(0.1) : Color.primary.opacity(0.05))
                    )
            }
            
            if isHovered || isSelected || item.isPinned {
                HStack(spacing: 4) {
                    if settingsManager.showPinButton || item.isPinned {
                        Button(action: onPin) {
                            Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(item.isPinned ? .yellow : (isSelected ? .white.opacity(0.8) : .secondary))
                                .padding(6)
                                .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help(item.isPinned ? settingsManager.localized("unpin") : settingsManager.localized("pin"))
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                            .padding(6)
                            .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(settingsManager.localized("delete"))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? (settingsManager.useCustomColors ? settingsManager.customAccentColor.color : Color.accentColor) : (isHovered ? Color.secondary.opacity(0.05) : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            if item.type == .image && thumbnail == nil {
                if let path = item.imagePath {
                    // Load off main thread to avoid stutter
                    DispatchQueue.global(qos: .userInitiated).async {
                        let img = ClipboardManager.shared.getImage(named: path)
                        DispatchQueue.main.async {
                            withAnimation {
                                self.thumbnail = img
                            }
                        }
                    }
                }
            }
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
