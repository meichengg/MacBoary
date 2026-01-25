//
//  SettingsManager.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation
import AppKit
import SwiftUI

enum PopupPosition: String, CaseIterable, Codable {
    case center = "center"
    case mouse = "mouse"
    
    var displayName: String {
        switch self {
        case .center: return SettingsManager.shared.localized("center_screen")
        case .mouse: return SettingsManager.shared.localized("mouse_position")
        }
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return SettingsManager.shared.localized("system")
        case .light: return SettingsManager.shared.localized("light")
        case .dark: return SettingsManager.shared.localized("dark")
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case system = "system"
    case english = "en"
    case german = "de"
    
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .german: return "Deutsch"
        }
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let showDockIconKey = "showDockIcon"
    private let shortcutKey = "globalShortcut"
    private let popupPositionKey = "popupPosition"
    private let quickPasteEnabledKey = "quickPasteEnabled"
    private let showPinButtonKey = "showPinButton"
    private let storeImagesKey = "storeImages"
    private let textRetentionDaysKey = "textRetentionDays"
    private let imageRetentionDaysKey = "imageRetentionDays"
    private let appThemeKey = "appTheme"
    private let appLanguageKey = "appLanguage"
    private let useCustomColorsKey = "useCustomColors"
    private let customAccentColorKey = "customAccentColor"
    private let customBackgroundColorKey = "customBackgroundColor"
    private let customSecondaryColorKey = "customSecondaryColor"
    
    @Published var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: appLanguageKey)
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    @Published var showDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(showDockIcon, forKey: showDockIconKey)
            updateDockIconVisibility()
        }
    }
    
    @Published var useCustomColors: Bool {
        didSet {
            UserDefaults.standard.set(useCustomColors, forKey: useCustomColorsKey)
        }
    }
    
    @Published var customAccentColor: ColorConfig {
        didSet {
            if let encoded = try? JSONEncoder().encode(customAccentColor) {
                UserDefaults.standard.set(encoded, forKey: customAccentColorKey)
            }
        }
    }
    
    @Published var customBackgroundColor: ColorConfig {
        didSet {
            if let encoded = try? JSONEncoder().encode(customBackgroundColor) {
                UserDefaults.standard.set(encoded, forKey: customBackgroundColorKey)
            }
        }
    }
    
    @Published var customSecondaryColor: ColorConfig {
        didSet {
            if let encoded = try? JSONEncoder().encode(customSecondaryColor) {
                UserDefaults.standard.set(encoded, forKey: customSecondaryColorKey)
            }
        }
    }
    
    @Published var quickPasteEnabled: Bool {
        didSet {
            UserDefaults.standard.set(quickPasteEnabled, forKey: quickPasteEnabledKey)
        }
    }
    
    @Published var showPinButton: Bool {
        didSet {
            UserDefaults.standard.set(showPinButton, forKey: showPinButtonKey)
        }
    }
    
    @Published var storeImages: Bool {
        didSet {
            UserDefaults.standard.set(storeImages, forKey: storeImagesKey)
        }
    }
    
    @Published var textRetentionDays: Int {
        didSet {
            UserDefaults.standard.set(textRetentionDays, forKey: textRetentionDaysKey)
        }
    }
    
    @Published var imageRetentionDays: Int {
        didSet {
            UserDefaults.standard.set(imageRetentionDays, forKey: imageRetentionDaysKey)
        }
    }
    
    @Published var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: appThemeKey)
        }
    }
    
    @Published var shortcut: GlobalKeyboardShortcut {
        didSet {
            if let encoded = try? JSONEncoder().encode(shortcut) {
                UserDefaults.standard.set(encoded, forKey: shortcutKey)
            }
        }
    }
    
    @Published var popupPosition: PopupPosition {
        didSet {
            UserDefaults.standard.set(popupPosition.rawValue, forKey: popupPositionKey)
        }
    }
    
    private init() {
        self.showDockIcon = UserDefaults.standard.object(forKey: showDockIconKey) as? Bool ?? false
        self.quickPasteEnabled = UserDefaults.standard.object(forKey: quickPasteEnabledKey) as? Bool ?? true
        self.showPinButton = UserDefaults.standard.object(forKey: showPinButtonKey) as? Bool ?? true
        self.storeImages = UserDefaults.standard.object(forKey: storeImagesKey) as? Bool ?? true
        self.textRetentionDays = UserDefaults.standard.object(forKey: textRetentionDaysKey) as? Int ?? 7
        self.imageRetentionDays = UserDefaults.standard.object(forKey: imageRetentionDaysKey) as? Int ?? 1
        
        self.useCustomColors = UserDefaults.standard.bool(forKey: useCustomColorsKey)
        
        if let accentData = UserDefaults.standard.data(forKey: customAccentColorKey),
           let decoded = try? JSONDecoder().decode(ColorConfig.self, from: accentData) {
            self.customAccentColor = decoded
        } else {
            self.customAccentColor = ColorConfig(color: .blue)
        }
        
        if let bgData = UserDefaults.standard.data(forKey: customBackgroundColorKey),
           let decoded = try? JSONDecoder().decode(ColorConfig.self, from: bgData) {
            self.customBackgroundColor = decoded
        } else {
            self.customBackgroundColor = ColorConfig(color: Color(nsColor: .windowBackgroundColor))
        }
        
        if let secData = UserDefaults.standard.data(forKey: customSecondaryColorKey),
           let decoded = try? JSONDecoder().decode(ColorConfig.self, from: secData) {
            self.customSecondaryColor = decoded
        } else {
            self.customSecondaryColor = ColorConfig(color: Color(nsColor: .controlBackgroundColor))
        }
        
        if let themeRaw = UserDefaults.standard.string(forKey: appThemeKey),
           let theme = AppTheme(rawValue: themeRaw) {
            self.appTheme = theme
        } else {
            self.appTheme = .system
        }
        
        if let langRaw = UserDefaults.standard.string(forKey: appLanguageKey),
           let lang = AppLanguage(rawValue: langRaw) {
            self.appLanguage = lang
        } else {
            self.appLanguage = .system
        }
        
        if let data = UserDefaults.standard.data(forKey: shortcutKey),
           let decoded = try? JSONDecoder().decode(GlobalKeyboardShortcut.self, from: data) {
            self.shortcut = decoded
        } else {
            self.shortcut = GlobalKeyboardShortcut.defaultShortcut
        }
        
        if let positionRaw = UserDefaults.standard.string(forKey: popupPositionKey),
           let position = PopupPosition(rawValue: positionRaw) {
            self.popupPosition = position
        } else {
            self.popupPosition = .center
        }
        
        updateDockIconVisibility()
    }
    
    func updateDockIconVisibility() {
        if showDockIcon {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    func localized(_ key: String) -> String {
        return Localization.string(key, language: appLanguage)
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}
