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
    private var encryptionKey: SymmetricKey?
    
    private init() {
        // Load or generate encryption key
        encryptionKey = loadOrCreateKey()
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
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyIdentifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing key first
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        SecItemAdd(query as CFDictionary, nil)
    }
    
    // MARK: - Encryption/Decryption
    
    func encrypt(_ string: String) -> String? {
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
