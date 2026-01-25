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
    var onSelect: (ClipboardItem) -> Void
    var onDelete: (ClipboardItem) -> Void
    var onPin: (ClipboardItem) -> Void
    
    // Cache filtered items to avoid recomputation on every render
    @State private var cachedFilteredItems: [ClipboardItem] = []
    
    // Compute filtered items only when search text or items change
    private func updateFilteredItems() {
        if viewModel.searchText.isEmpty {
            cachedFilteredItems = clipboardManager.items
        } else {
            cachedFilteredItems = clipboardManager.items.filter {
                $0.content.localizedCaseInsensitiveContains(viewModel.searchText)
            }
        }
    }
    
    var filteredItems: [ClipboardItem] {
        cachedFilteredItems
    }
    
    // Focus state for search field
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
                .opacity(0.4)
            
            permissionWarningView
            
            contentView
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
        .onChange(of: clipboardManager.items) { _ in
            updateFilteredItems()
        }
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
                    .onChange(of: viewModel.searchText) { _ in
                        updateFilteredItems()
                    }
                    .onAppear {
                        // Auto focus when created
                        isSearchFocused = true
                        updateFilteredItems()
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
    private var permissionWarningView: some View {
        if !PermissionManager.shared.hasAccessibilityPermission {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                Text(settingsManager.localized("permission_warning"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Button(settingsManager.localized("grant_access")) {
                    PermissionManager.shared.openAccessibilityPreferences()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            
            Divider()
                .opacity(0.4)
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
                    LazyVStack(spacing: 4) {
                        let visibleItems = Array(filteredItems.prefix(viewModel.displayedLimit).enumerated())
                        
                        ForEach(visibleItems, id: \.element.id) { index, item in
                            ClipboardItemRow(
                                item: item,
                                index: index,
                                isSelected: index == viewModel.selectionIndex,
                                onSelect: { onSelect(item) },
                                onDelete: { onDelete(item) },
                                onPin: { onPin(item) }
                            )
                            .id("item-\(item.id.uuidString)")
                        }
                        
                        if filteredItems.count > viewModel.displayedLimit {
                            Button(action: {
                                withAnimation {
                                    viewModel.displayedLimit += viewModel.pageSize
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Text(settingsManager.localized("load_more"))
                                        .font(.system(size: 13, weight: .medium))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11))
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(viewModel.selectionIndex == viewModel.displayedLimit ? Color.accentColor : Color.secondary.opacity(0.1))
                                )
                                .foregroundColor(viewModel.selectionIndex == viewModel.displayedLimit ? .white : .primary)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .id("load-more-\(viewModel.displayedLimit)")
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .id(viewModel.displayedLimit) // Force re-render when limit changes
                }
                .onChange(of: viewModel.selectionIndex) { newIndex in
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
        
        footerView
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
                        // Load thumbnail instead of full image
                        let img = ClipboardManager.shared.getThumbnail(named: path, maxDimension: 300)
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
