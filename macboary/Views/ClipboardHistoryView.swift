//
//  ClipboardHistoryView.swift
//  macboary
//
//  Created by Marco Baeuml on 24/01/2026.
//

import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @ObservedObject var settingsManager = SettingsManager.shared
    @ObservedObject var viewModel: HistoryViewModel
    
    // Actions
    var onConfirm: (ClipboardItem) -> Void // Double click or Enter -> Stick/Paste
    var onSelect: (ClipboardItem) -> Void  // Single click or Arrow -> Highlight/Preview
    var onDelete: (ClipboardItem) -> Void
    var onPin: (ClipboardItem) -> Void
    
    // Computed property for filtered items - recalculates when dependencies change
    // Computed property for filtered items - usage of ViewModel's optimized list
    private var filteredItems: [ClipboardItem] {
        return viewModel.filteredItems
    }
    
    // Focus state for search field
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
                .opacity(0.4)
            
            // Permission warning removed as it is handled at app launch
            
            // Split Content View
            HStack(spacing: 0) {
                // Left Column: List (40%)
                contentView
                    .frame(width: 300)
                
                Divider()
                
                // Right Column: Preview (60%)
                ClipboardPreviewView(
                    item: selectedItem,
                    searchText: viewModel.searchText
                )
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 750, height: 500)
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
    
    // Helper to get selected item safely
    private var selectedItem: ClipboardItem? {
        // If searching, items might change order, but selectionIndex acts on displayed list
        if viewModel.selectionIndex >= 0 && viewModel.selectionIndex < filteredItems.count {
            return filteredItems[viewModel.selectionIndex]
        }
        return nil
    }
    
    // Extract header into computed property to help type checker
    private var headerView: some View {
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
                    .onChange(of: viewModel.shouldFocusSearch) { _ in
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
    }
    

    
    @ViewBuilder
    private var contentView: some View {
        if filteredItems.isEmpty {
            VStack(spacing: 12) {
                if viewModel.searchText.isEmpty {
                    Image("EmptyListIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .opacity(0.8)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                
                Text(viewModel.searchText.isEmpty ? settingsManager.localized("no_history") : settingsManager.localized("no_results"))
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear) // Transparent list background
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        let visibleItems = Array(filteredItems.prefix(viewModel.displayedLimit).enumerated())
                        
                        ForEach(visibleItems, id: \.element.id) { index, item in
                            ClipboardItemRow(
                                item: item,
                                index: index,
                                isSelected: index == viewModel.selectionIndex,
                                onConfirm: { onConfirm(item) },
                                onSelect: { onSelect(item) },
                                onDelete: { onDelete(item) },
                                onPin: { onPin(item) }
                            )
                            .id("item-\(item.id.uuidString)")
                        }
                        
                        if filteredItems.count > viewModel.displayedLimit {
                            // Infinite scroll loader
                            Color.clear
                                .frame(height: 20)
                                .onAppear {
                                    viewModel.loadMore()
                                }
                                .id("load-more-\(viewModel.displayedLimit)")
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .id(viewModel.displayedLimit) // Force re-render when limit changes
                }
                .onChange(of: viewModel.scrollToIndex) { newIndex in
                    guard let newIndex = newIndex else { return }
                    // Scroll to item
                    if newIndex >= 0 && newIndex < filteredItems.count {
                        let item = filteredItems[newIndex]
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo("item-\(item.id.uuidString)", anchor: .center)
                        }
                    } else if newIndex == viewModel.displayedLimit && filteredItems.count > viewModel.displayedLimit {
                        // Scroll to load more button
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo("load-more-\(viewModel.displayedLimit)", anchor: .center)
                        }
                    }
                }
            }
        }
        
        // Remove footer view from here as it's better placed in the list column if needed, or omitted for cleaner UI
        // footerView 
    }
    
    private var footerView: some View {
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
    
    var onConfirm: () -> Void // Double click
    var onSelect: () -> Void  // Single click
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
                    if item.type == .file { return "doc" }
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

                } else if item.type == .file {
                     // File Item
                     HStack(spacing: 8) {
                         if let path = item.filePath {
                             Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                                 .resizable()
                                 .aspectRatio(contentMode: .fit)
                                 .frame(width: 32, height: 32)
                         } else {
                             Image(systemName: "doc.fill")
                                 .font(.system(size: 24))
                                 .foregroundColor(.secondary)
                         }
                         
                         Text(item.displayText)
                             .font(.system(size: 13, weight: .medium))
                             .lineLimit(1)
                             .truncationMode(.middle)
                             .foregroundColor(isSelected ? .white : .primary)
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
        .onTapGesture(count: 2) {
            onConfirm()
        }
        .simultaneousGesture(TapGesture().onEnded {
            onSelect()
        })
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            if item.type == .image && thumbnail == nil {
                if let path = item.imagePath {
                     Task {
                        // Offload I/O to detached task if getThumbnail is safe or ensure getThumbnail runs on correct actor
                        // But getThumbnail in ClipboardManager is NOT isolated to non-main actor? 
                        // Actually ClipboardManager is @MainActor, so calling it from background is tricky unless detached.
                        
                        // We need to fetch data. Let's do it carefully.
                        // Since ClipboardManager is @MainActor, we should let it do the heavy lifting on a detached task IF it was designed so.
                        // But getThumbnail is synchronous. We should move the heavy lifting inside getThumbnail to a detached task or similar?
                        // Or just call it here. But we are on MainActor in .onAppear.
                        // The previous code had DispatchQueue.global.
                        
                        // Better approach: Use Task.detached for the IO, accessing ONLY the path string (captured), then update MainActor.
                        let loadedCGImage = await Task.detached(priority: .userInitiated) { () -> CGImage? in
                            return ClipboardHelper.loadThumbnail(path: path)
                        }.value
                        
                        if let cgImg = loadedCGImage {
                            await MainActor.run {
                                let nsImage = NSImage(cgImage: cgImg, size: NSSize(width: CGFloat(cgImg.width), height: CGFloat(cgImg.height)))
                                withAnimation {
                                    self.thumbnail = nsImage
                                }
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
        onConfirm: { _ in },
        onSelect: { _ in },
        onDelete: { _ in },
        onPin: { _ in }
    )
}
