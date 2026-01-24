//
//  SettingsView.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import SwiftUI
import Carbon

struct SettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var isRecordingShortcut = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $settingsManager.showDockIcon) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show in Dock")
                        Text("If disabled, app runs in menu bar only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Picker("Popup Position", selection: $settingsManager.popupPosition) {
                    ForEach(PopupPosition.allCases, id: \.self) { position in
                        Text(position.displayName).tag(position)
                    }
                }
            } header: {
                Label("Appearance", systemImage: "paintbrush")
            }
            
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Global Hotkey")
                        Button("Reset to Default (⌘⇧V)") {
                            settingsManager.shortcut = GlobalKeyboardShortcut.defaultShortcut
                            NotificationCenter.default.post(name: .shortcutChanged, object: nil)
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                        .controlSize(.mini)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isRecordingShortcut = true
                    }) {
                        Text(isRecordingShortcut ? "Rec..." : settingsManager.shortcut.displayString)
                            .lineLimit(1)
                            .frame(minWidth: 80, alignment: .center)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isRecordingShortcut ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isRecordingShortcut ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Label("Keyboard", systemImage: "keyboard")
            }
            
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility Access")
                        Text("Required for global hotkey and pasting")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if PermissionManager.shared.hasAccessibilityPermission {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Granted")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button("Grant Access") {
                            PermissionManager.shared.openAccessibilityPreferences()
                        }
                    }
                }
            } header: {
                Label("Permissions", systemImage: "lock.shield")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 500)
        .background(
            ShortcutRecorderView(
                isRecording: $isRecordingShortcut,
                onShortcutRecorded: { shortcut in
                    settingsManager.shortcut = shortcut
                    NotificationCenter.default.post(name: .shortcutChanged, object: nil)
                }
            )
        )
    }
}

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onShortcutRecorded: (GlobalKeyboardShortcut) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = ShortcutRecorderNSView()
        view.onShortcutRecorded = { shortcut in
            onShortcutRecorded(shortcut)
            isRecording = false
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? ShortcutRecorderNSView {
            view.isRecording = isRecording
        }
    }
}

class ShortcutRecorderNSView: NSView {
    var isRecording = false
    var onShortcutRecorded: ((GlobalKeyboardShortcut) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        let modifiers = event.modifierFlags
        var carbonModifiers: UInt32 = 0
        
        if modifiers.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifiers.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        if modifiers.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        
        // Require at least one modifier
        guard carbonModifiers != 0 else { return }
        
        let shortcut = GlobalKeyboardShortcut(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers)
        onShortcutRecorded?(shortcut)
    }
}

extension Notification.Name {
    static let shortcutChanged = Notification.Name("shortcutChanged")
}

#Preview {
    SettingsView()
}
