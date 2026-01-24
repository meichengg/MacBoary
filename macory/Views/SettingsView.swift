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
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            Form {
                Section {
                    Toggle("Show in Dock", isOn: $settingsManager.showDockIcon)
                    Text("When disabled, Macory runs as a menu bar only app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Popup Position", selection: $settingsManager.popupPosition) {
                        ForEach(PopupPosition.allCases, id: \.self) { position in
                            Text(position.displayName).tag(position)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Label("Appearance", systemImage: "paintbrush")
                }
                
                Section {
                    HStack {
                        Text("Global Hotkey")
                        Spacer()
                        Button(action: {
                            isRecordingShortcut = true
                        }) {
                            Text(isRecordingShortcut ? "Press keys..." : settingsManager.shortcut.displayString)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isRecordingShortcut ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isRecordingShortcut ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("Click to change the keyboard shortcut")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Reset to Default (⌘⇧V)") {
                        settingsManager.shortcut = GlobalKeyboardShortcut.defaultShortcut
                        NotificationCenter.default.post(name: .shortcutChanged, object: nil)
                    }
                    .font(.caption)
                } header: {
                    Label("Keyboard", systemImage: "keyboard")
                }
                
                Section {
                    HStack {
                        Text("Accessibility")
                        Spacer()
                        if PermissionManager.shared.hasAccessibilityPermission {
                            Label("Granted", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Button("Grant Access") {
                                PermissionManager.shared.openAccessibilityPreferences()
                            }
                        }
                    }
                    
                    Text("Required for global hotkey and pasting")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Label("Permissions", systemImage: "lock.shield")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 400)
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
