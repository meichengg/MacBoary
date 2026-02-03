//
//  PasswordPromptView.swift
//  macboary
//
//  Created by Marco Baeuml on 04/02/2026.
//

import SwiftUI

struct PasswordPromptView: View {
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var isSettingPassword: Bool
    
    let onSuccess: () -> Void
    let onCancel: (() -> Void)?
    
    init(isSettingPassword: Bool, onSuccess: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self._isSettingPassword = State(initialValue: isSettingPassword)
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isSettingPassword ? "lock.shield" : "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text(isSettingPassword ? "Set Encryption Password" : "Enter Password")
                .font(.headline)
            
            Text(isSettingPassword ? 
                 "Choose a password to protect your clipboard history. You'll need to enter this password when opening the app." :
                 "Enter your password to unlock clipboard history.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
                .onSubmit {
                    if !isSettingPassword {
                        attemptUnlock()
                    }
                }
            
            if isSettingPassword {
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .onSubmit {
                        attemptSetPassword()
                    }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack(spacing: 12) {
                if onCancel != nil {
                    Button("Cancel") {
                        onCancel?()
                    }
                    .keyboardShortcut(.escape)
                }
                
                Button(isSettingPassword ? "Set Password" : "Unlock") {
                    if isSettingPassword {
                        attemptSetPassword()
                    } else {
                        attemptUnlock()
                    }
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty || (isSettingPassword && confirmPassword.isEmpty))
            }
        }
        .padding(30)
        .frame(width: 350)
    }
    
    private func attemptSetPassword() {
        guard !password.isEmpty else {
            errorMessage = "Password cannot be empty"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard password.count >= 4 else {
            errorMessage = "Password must be at least 4 characters"
            return
        }
        
        if EncryptionService.shared.setPassword(password) {
            onSuccess()
        } else {
            errorMessage = "Failed to set password"
        }
    }
    
    private func attemptUnlock() {
        guard !password.isEmpty else {
            errorMessage = "Password cannot be empty"
            return
        }
        
        if EncryptionService.shared.unlock(password: password) {
            onSuccess()
        } else {
            errorMessage = "Incorrect password"
            password = ""
        }
    }
}

#Preview("Set Password") {
    PasswordPromptView(isSettingPassword: true, onSuccess: {})
}

#Preview("Unlock") {
    PasswordPromptView(isSettingPassword: false, onSuccess: {})
}
