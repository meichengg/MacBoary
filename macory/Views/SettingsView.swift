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
            // General
            Section {
                Picker(settingsManager.localized("language"), selection: $settingsManager.appLanguage) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                
                Toggle(isOn: $settingsManager.showDockIcon) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settingsManager.localized("show_dock"))
                        Text(settingsManager.localized("show_dock_desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(settingsManager.localized("quit")) {
                    NSApplication.shared.terminate(nil)
                }
            } header: {
                Label(settingsManager.localized("general"), systemImage: "gear")
            }
            
            // Appearance
            Section {
                Picker(settingsManager.localized("window_position"), selection: $settingsManager.popupPosition) {
                    ForEach(PopupPosition.allCases, id: \.self) { position in
                        Text(position.displayName).tag(position)
                    }
                }
                
                Toggle(settingsManager.localized("pin"), isOn: $settingsManager.showPinButton)
                
                Picker(settingsManager.localized("theme"), selection: $settingsManager.appTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                
                Toggle(settingsManager.localized("use_custom_colors"), isOn: $settingsManager.useCustomColors)
                
                if settingsManager.useCustomColors {
                    ColorPicker(settingsManager.localized("accent_color"), selection: Binding(
                        get: { settingsManager.customAccentColor.color },
                        set: { settingsManager.customAccentColor = ColorConfig(color: $0) }
                    ))
                    
                    ColorPicker(settingsManager.localized("background_color"), selection: Binding(
                        get: { settingsManager.customBackgroundColor.color },
                        set: { settingsManager.customBackgroundColor = ColorConfig(color: $0) }
                    ))
                    
                    ColorPicker(settingsManager.localized("secondary_color"), selection: Binding(
                        get: { settingsManager.customSecondaryColor.color },
                        set: { settingsManager.customSecondaryColor = ColorConfig(color: $0) }
                    ))
                    
                    Text(settingsManager.localized("secondary_color_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Label(settingsManager.localized("appearance"), systemImage: "paintbrush")
            }
            
            // Storage
            Section {
                Picker(settingsManager.localized("text_retention"), selection: $settingsManager.textRetentionDays) {
                    Text(settingsManager.localized("disabled")).tag(0)
                    Text("1 \(settingsManager.localized("days"))").tag(1)
                    Text("3 \(settingsManager.localized("days"))").tag(3)
                    Text("7 \(settingsManager.localized("days"))").tag(7)
                    Text("14 \(settingsManager.localized("days"))").tag(14)
                    Text("30 \(settingsManager.localized("days"))").tag(30)
                    Text(settingsManager.localized("forever")).tag(-1)
                }
                
                Picker(settingsManager.localized("image_retention"), selection: $settingsManager.imageRetentionDays) {
                    Text(settingsManager.localized("disabled")).tag(0)
                    Text("1 \(settingsManager.localized("days"))").tag(1)
                    Text("3 \(settingsManager.localized("days"))").tag(3)
                    Text("7 \(settingsManager.localized("days"))").tag(7)
                    Text("14 \(settingsManager.localized("days"))").tag(14)
                    Text("30 \(settingsManager.localized("days"))").tag(30)
                    Text(settingsManager.localized("forever")).tag(-1)
                }
            } header: {
                Label(settingsManager.localized("storage"), systemImage: "clock")
            }
            
            // Shortcuts
            Section {
                Toggle(isOn: $settingsManager.quickPasteEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settingsManager.localized("quick_paste"))
                        Text(settingsManager.localized("quick_paste_desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settingsManager.localized("global_hotkey"))
                        Button(settingsManager.localized("reset_default")) {
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
                Label(settingsManager.localized("shortcuts"), systemImage: "keyboard")
            }
            
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settingsManager.localized("accessibility_access"))

                        Text(settingsManager.localized("accessibility_desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if PermissionManager.shared.hasAccessibilityPermission {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(settingsManager.localized("granted"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(settingsManager.localized("grant_access")) {
                            PermissionManager.shared.openAccessibilityPreferences()
                        }
                    }
                }
            } header: {
                Label(settingsManager.localized("permissions"), systemImage: "lock.shield")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 600)
        .preferredColorScheme(settingsManager.appTheme.colorScheme)
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
