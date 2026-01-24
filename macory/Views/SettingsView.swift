//
//  SettingsView.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import SwiftUI
import Carbon
import AppKit

struct SettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
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
                
                Toggle("Show Pin Button", isOn: $settingsManager.showPinButton)
                
                Toggle(isOn: $settingsManager.storeImages) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Store Images")
                        Text("Save copied images to history")
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
                Picker("Keep text history for", selection: $settingsManager.textRetentionDays) {
                    Text("1 Day").tag(1)
                    Text("3 Days").tag(3)
                    Text("7 Days").tag(7)
                    Text("30 Days").tag(30)
                }
                
                Picker("Keep image history for", selection: $settingsManager.imageRetentionDays) {
                    Text("1 Day").tag(1)
                    Text("3 Days").tag(3)
                    Text("7 Days").tag(7)
                    Text("30 Days").tag(30)
                }
            } header: {
                Label("History", systemImage: "clock")
            }
            
            Section {
                Toggle(isOn: $settingsManager.quickPasteEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Quick Paste Shortcuts")
                        Text("Use ⌘1-9 to paste the first 9 items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
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
                    
                    ShortcutRecorder(shortcut: $settingsManager.shortcut)
                        .frame(width: 120, height: 24)
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
        .frame(width: 400, height: 600)
    }
}

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: GlobalKeyboardShortcut
    
    func makeNSView(context: Context) -> RecorderControl {
        let view = RecorderControl()
        view.shortcut = shortcut
        view.delegate = context.coordinator
        return view
    }
    
    func updateNSView(_ nsView: RecorderControl, context: Context) {
        nsView.shortcut = shortcut
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: RecorderControlDelegate {
        var parent: ShortcutRecorder
        
        init(_ parent: ShortcutRecorder) {
            self.parent = parent
        }
        
        func didRecordShortcut(_ shortcut: GlobalKeyboardShortcut) {
            parent.shortcut = shortcut
            NotificationCenter.default.post(name: .shortcutChanged, object: nil)
        }
    }
}

protocol RecorderControlDelegate: AnyObject {
    func didRecordShortcut(_ shortcut: GlobalKeyboardShortcut)
}

class RecorderControl: NSView {
    var shortcut: GlobalKeyboardShortcut? {
        didSet {
            if !isRecording {
                updateDisplay()
            }
        }
    }
    weak var delegate: RecorderControlDelegate?
    
    private var isRecording = false {
        didSet {
            updateDisplay()
            needsDisplay = true
        }
    }
    
    private let label = NSTextField(labelWithString: "")
    private var trackingArea: NSTrackingArea?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 5
        
        label.alignment = .center
        label.font = .systemFont(ofSize: 13)
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        
        updateDisplay()
    }
    
    override func layout() {
        super.layout()
        label.frame = NSRect(x: 0, y: (bounds.height - 16) / 2, width: bounds.width, height: 16)
    }

    override func updateTrackingAreas() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
        
        super.updateTrackingAreas()
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func becomeFirstResponder() -> Bool {
        isRecording = true
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }
    
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        if event.keyCode == 53 { // Escape
            window?.makeFirstResponder(nil)
            return
        }
        
        let modifiers = event.modifierFlags
        var carbonModifiers: UInt32 = 0
        if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        if modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        
        if carbonModifiers == 0 && !isFunctionKey(event.keyCode) {
            NSSound.beep()
            return
        }
        
        let newShortcut = GlobalKeyboardShortcut(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers)
        delegate?.didRecordShortcut(newShortcut)
        
        window?.makeFirstResponder(nil)
    }
    
    override func flagsChanged(with event: NSEvent) {
        if isRecording {
            let flags = event.modifierFlags
            var text = ""
            if flags.contains(.control) { text += "⌃" }
            if flags.contains(.option) { text += "⌥" }
            if flags.contains(.shift) { text += "⇧" }
            if flags.contains(.command) { text += "⌘" }
            
            if !text.isEmpty {
                label.stringValue = text
            } else {
                label.stringValue = "Type Shortcut"
            }
        }
        super.flagsChanged(with: event)
    }
    
    private func updateDisplay() {
        if isRecording {
            layer?.backgroundColor = NSColor.selectedControlColor.cgColor
            label.textColor = .selectedControlTextColor
            label.stringValue = "Type Shortcut"
            layer?.borderWidth = 2
            layer?.borderColor = NSColor.keyboardFocusIndicatorColor.cgColor
        } else {
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            label.textColor = .labelColor
            label.stringValue = shortcut?.displayString ?? "None"
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.separatorColor.cgColor
        }
    }
    
    private func isFunctionKey(_ code: UInt16) -> Bool {
        return (code >= 96 && code <= 101) || (code >= 109 && code <= 111) || (code >= 118 && code <= 122)
    }
}

extension Notification.Name {
    static let shortcutChanged = Notification.Name("shortcutChanged")
}

#Preview {
    SettingsView()
}
