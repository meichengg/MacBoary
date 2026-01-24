//
//  SettingsManager.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import Foundation
import AppKit

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let showDockIconKey = "showDockIcon"
    private let shortcutKey = "globalShortcut"
    
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
    
    private init() {
        self.showDockIcon = UserDefaults.standard.object(forKey: showDockIconKey) as? Bool ?? false
        
        if let data = UserDefaults.standard.data(forKey: shortcutKey),
           let decoded = try? JSONDecoder().decode(GlobalKeyboardShortcut.self, from: data) {
            self.shortcut = decoded
        } else {
            self.shortcut = GlobalKeyboardShortcut.defaultShortcut
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
