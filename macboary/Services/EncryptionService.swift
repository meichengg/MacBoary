//
//  EncryptionService.swift
//  macboary
//
//  Created by Marco Baeuml on 25/01/2026.
//

import Foundation
import CryptoKit
import CommonCrypto

class EncryptionService {
    static let shared = EncryptionService()
    
    private let saltKey = "com.macboary.encryption.salt"
    private let verifierKey = "com.macboary.encryption.verifier"
    
    // Current encryption key (derived from password)
    private var _encryptionKey: SymmetricKey?
    
    // Is encryption unlocked this session?
    var isUnlocked: Bool {
        return _encryptionKey != nil
    }
    
    // Is encryption enabled and configured (password set)?
    var isConfigured: Bool {
        return UserDefaults.standard.bool(forKey: "encryptionEnabled") &&
               UserDefaults.standard.data(forKey: saltKey) != nil
    }
    
    private init() {}
    
    // MARK: - Password Management
    
    /// Set a new password (first time or change password)
    func setPassword(_ password: String) -> Bool {
        guard !password.isEmpty else { return false }
        
        // Generate random salt
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
        
        // Derive key from password
        guard let key = deriveKey(from: password, salt: salt) else { return false }
        
        // Create verifier (encrypt a known string to verify password later)
        let verifierPlaintext = "MACBOARY_VERIFIER"
        guard let verifierData = verifierPlaintext.data(using: .utf8) else { return false }
        
        do {
            let sealedBox = try AES.GCM.seal(verifierData, using: key)
            guard let combined = sealedBox.combined else { return false }
            
            // Save salt and verifier
            UserDefaults.standard.set(salt, forKey: saltKey)
            UserDefaults.standard.set(combined, forKey: verifierKey)
            UserDefaults.standard.set(true, forKey: "encryptionEnabled")
            
            // Keep key in memory
            _encryptionKey = key
            
            return true
        } catch {
            print("❌ Failed to create verifier: \(error)")
            return false
        }
    }
    
    /// Unlock encryption with password
    func unlock(password: String) -> Bool {
        guard let salt = UserDefaults.standard.data(forKey: saltKey),
              let verifierData = UserDefaults.standard.data(forKey: verifierKey) else {
            return false
        }
        
        guard let key = deriveKey(from: password, salt: salt) else { return false }
        
        // Verify password by decrypting verifier
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: verifierData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            let verifierString = String(data: decryptedData, encoding: .utf8)
            
            if verifierString == "MACBOARY_VERIFIER" {
                _encryptionKey = key
                return true
            }
        } catch {
            print("❌ Password verification failed: \(error)")
        }
        
        return false
    }
    
    /// Lock encryption (clear key from memory)
    func lock() {
        _encryptionKey = nil
    }
    
    /// Remove password and disable encryption
    func removePassword() {
        _encryptionKey = nil
        UserDefaults.standard.removeObject(forKey: saltKey)
        UserDefaults.standard.removeObject(forKey: verifierKey)
        UserDefaults.standard.set(false, forKey: "encryptionEnabled")
    }
    
    // MARK: - Key Derivation (PBKDF2)
    
    private func deriveKey(from password: String, salt: Data) -> SymmetricKey? {
        guard let passwordData = password.data(using: .utf8) else { return nil }
        
        var derivedKeyData = Data(count: 32) // 256 bits
        
        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        100_000, // iterations (balance between security and speed)
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            print("❌ PBKDF2 key derivation failed")
            return nil
        }
        
        return SymmetricKey(data: derivedKeyData)
    }
    
    // MARK: - Encryption/Decryption
    
    func encrypt(_ string: String) -> String? {
        guard UserDefaults.standard.bool(forKey: "encryptionEnabled") else {
            return string // Return unencrypted if disabled
        }
        
        guard let key = _encryptionKey,
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
        guard let key = _encryptionKey,
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
    
    /// Decrypt data using a specific password and salt (for import with backup's credentials)
    func decryptDataWithCredentials(password: String, salt: Data, encryptedData: Data) -> Data? {
        guard let key = deriveKey(from: password, salt: salt) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Decryption with credentials error: \(error)")
            return nil
        }
    }
    
    func encryptData(_ data: Data) -> Data? {
        guard UserDefaults.standard.bool(forKey: "encryptionEnabled") else {
            return data // Return unencrypted if disabled
        }
        
        guard let key = _encryptionKey else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Data encryption error: \(error)")
            return nil
        }
    }
    
    func decryptData(_ encryptedData: Data) -> Data? {
        // If encryption is disabled, return as-is
        guard UserDefaults.standard.bool(forKey: "encryptionEnabled") else {
            return encryptedData
        }
        
        // If we have a key, try to decrypt
        if let key = _encryptionKey {
            do {
                let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
                return try AES.GCM.open(sealedBox, using: key)
            } catch {
                // Decryption failed - might be unencrypted data from before encryption was enabled
                // Try to return as-is if it looks like valid image data
                if encryptedData.count > 4 {
                    // Check for common image magic bytes
                    let header = encryptedData.prefix(4)
                    // PNG: 89 50 4E 47, JPEG: FF D8 FF, GIF: 47 49 46, TIFF: 49 49/4D 4D
                    if header.starts(with: [0x89, 0x50, 0x4E, 0x47]) || // PNG
                       header.starts(with: [0xFF, 0xD8, 0xFF]) || // JPEG
                       header.starts(with: [0x47, 0x49, 0x46]) { // GIF
                        return encryptedData
                    }
                }
                print("Data decryption error: \(error)")
                return nil
            }
        }
        
        // No key available - check if this is unencrypted image data
        if encryptedData.count > 4 {
            let header = encryptedData.prefix(4)
            if header.starts(with: [0x89, 0x50, 0x4E, 0x47]) || // PNG
               header.starts(with: [0xFF, 0xD8, 0xFF]) || // JPEG
               header.starts(with: [0x47, 0x49, 0x46]) { // GIF
                return encryptedData
            }
        }
        
        return nil
    }
}
