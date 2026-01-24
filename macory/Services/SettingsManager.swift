//
//  SettingsManager.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation
import AppKit

enum PopupPosition: String, CaseIterable, Codable {
    case center = "center"
    case mouse = "mouse"
    
    var displayName: String {
        switch self {
        case .center: return "Center of Screen"
        case .mouse: return "At Mouse Position"
        }
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let showDockIconKey = "showDockIcon"
    private let shortcutKey = "globalShortcut"
    private let popupPositionKey = "popupPosition"
    
    @Published var showDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(showDockIcon, forKey: showDockIconKey)
            updateDockIconVisibility()
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
    }
    
    func updateDockIconVisibility() {
        if showDockIcon {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
