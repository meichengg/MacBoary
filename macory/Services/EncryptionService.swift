//
//  EncryptionService.swift
//  macory
//
//  Created by Marco Baeuml on 25/01/2026.
//

import Foundation
import CryptoKit
import Security

class EncryptionService {
    static let shared = EncryptionService()
    
    private let keyIdentifier = "com.macory.encryption.key"
    
    // Lazy loaded key
    private var _encryptionKey: SymmetricKey?
    private var encryptionKey: SymmetricKey? {
        // Only load if encryption is enabled or we need to access it explicitly
        // Logic: if _encryptionKey is loaded, return it.
        // If not, check if we should load it.
        if let key = _encryptionKey {
            return key
        }
        
        // If encryption is enabled, try to load/create
        if UserDefaults.standard.bool(forKey: "encryptionEnabled") {
            _encryptionKey = loadOrCreateKey()
            return _encryptionKey
        }
        
        return nil
    }
    
    private init() {
        // Do not load key in init to prevent early Keychain access prompt
    }
    
    // MARK: - Key Management
    
    private func loadOrCreateKey() -> SymmetricKey {
        // Try to load existing key from Keychain
        if let existingKey = loadKeyFromKeychain() {
            return existingKey
        }
        
        // Generate new key if none exists
        let newKey = SymmetricKey(size: .bits256)
        saveKeyToKeychain(newKey)
        return newKey
    }
    
    private func loadKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyIdentifier,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    private func saveKeyToKeychain(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Create access control that allows the app to access without prompting
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleAfterFirstUnlock,
            [],  // No additional flags - allows access without user interaction
            nil
        ) else {
            print("Failed to create access control")
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyIdentifier,
            kSecValueData as String: keyData,
            kSecAttrAccessControl as String: access
        ]
        
        // Delete any existing key first
        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            print("Warning: Failed to delete existing keychain item: \(deleteStatus)")
            // Continue anyway - the add might still work
        }
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to save key to keychain: \(status)")
        }
    }
    
    // MARK: - Keychain Access Status
    
    func hasKeychainAccess() -> Bool {
        // Try to access the key to verify Keychain access
        return encryptionKey != nil
    }
    
    // MARK: - Encryption/Decryption
    
    func encrypt(_ string: String) -> String? {
        // Check if encryption is enabled (direct UserDefaults access to avoid actor isolation issues)
        guard UserDefaults.standard.bool(forKey: "encryptionEnabled") else {
            return string // Return unencrypted if disabled
        }
        
        guard let key = encryptionKey,
              let data = string.data(using: .utf8) else {
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else { return nil }
            return combined.base64EncodedString()
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    func decrypt(_ encryptedString: String) -> String? {
        guard let key = encryptionKey,
              let combinedData = Data(base64Encoded: encryptedString) else {
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
    
    func encryptData(_ data: Data) -> Data? {
        // Check if encryption is enabled (direct UserDefaults access to avoid actor isolation issues)
        guard UserDefaults.standard.bool(forKey: "encryptionEnabled") else {
            return data // Return unencrypted if disabled
        }
        
        guard let key = encryptionKey else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Data encryption error: \(error)")
            return nil
        }
    }
    
    func decryptData(_ encryptedData: Data) -> Data? {
        guard let key = encryptionKey else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Data decryption error: \(error)")
            return nil
        }
    }
}
