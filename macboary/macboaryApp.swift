//
//  macboaryApp.swift
//  macboary
//
//  Created by Marco Baeuml on 24/01/2026.
//

import SwiftUI

@main
struct macboaryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Settings scene for Cmd+, shortcut
        Settings {
            SettingsView()
        }
    }
}
