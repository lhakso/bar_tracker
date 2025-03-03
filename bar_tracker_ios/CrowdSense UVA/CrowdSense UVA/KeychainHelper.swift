//
//  KeychainHelper.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/22/25.
//

import SwiftUI
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    /// Save data to Keychain
    func save(_ data: Data, service: String, account: String) -> Bool {
        // Create query
        print("saved data to keychain, service: \(service), account: \(account)")
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecValueData as String   : data,
            // Set accessibility to ensure the token is available after the first unlock
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Add to Keychain
        SecItemDelete(query as CFDictionary) // Delete any existing item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve data from Keychain
    func retrieve(service: String, account: String) -> Data? {
        print("Retrieving data from keychain, service: \(service), account: \(account)")
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecReturnData as String  : true,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            print("✅ Successfully retrieved data from keychain")
            return data
        } else {
            print("❌ Failed to retrieve from keychain, error code: \(status), description: \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")")
            return nil
        }
    }
    
    /// Delete data from Keychain
    func delete(service: String, account: String) -> Bool {
        print("DELETED FROM KEYCHAIN, SERVICE: \(service), ACCOUNT: \(account)")
        // Create query
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        
        // Delete item
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
