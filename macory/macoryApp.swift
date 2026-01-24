//
//  macoryApp.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import SwiftUI

@main
struct macoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty Settings scene - we handle everything via AppDelegate and menu bar
        Settings {
            EmptyView()
        }
    }
}
