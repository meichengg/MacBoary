//
//  AboutView.swift
//  macory
//
//  Created by Marco Baeuml on 24/01/2026.
//

import SwiftUI

struct AboutView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            Image("AboutIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
            
            // App Name
            Text("Macory")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Tagline
            Text("Clipboard History Manager")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Version
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal, 40)
            
            // Description
            VStack(spacing: 8) {
                Text("A lightweight clipboard history manager")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            
            Spacer()
            
            // Copyright
            Text("© 2026 Marco Baeuml")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(30)
        .frame(width: 300, height: 350)
        .preferredColorScheme(settingsManager.appTheme.colorScheme)
    }
}

#Preview {
    AboutView()
}
