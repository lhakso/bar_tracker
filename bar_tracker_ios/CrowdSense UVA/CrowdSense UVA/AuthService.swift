//
//  AuthService.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/17/25.
//

import Foundation

class AuthService {
    static let shared = AuthService()

    // In-memory token (not persisted). In production, store securely (e.g., Keychain).
    private let service = "com.yourapp.CrowdSense"
    private let tokenService = "com.yourapp.CrowdSenseToken"
    private let tokenAccount = "authToken"
    private let userInfoService = "com.yourapp.CrowdSenseUserInfo"
    private let usernameAccount = "username"
    private let emailAccount = "email"
    private let account = "authToken"
    private init() {}

    // MARK: - User Info (Not needed for anonymous token flow)
    /*
    func saveUserInfo(username: String) {
        let _ = KeychainHelper.shared.save(username.data(using: .utf8)!, service: userInfoService, account: usernameAccount)
    }

    func getUserInfo() -> (username: String?, email: String?) {
        let usernameData = KeychainHelper.shared.retrieve(service: userInfoService, account: usernameAccount)
        let emailData = KeychainHelper.shared.retrieve(service: userInfoService, account: emailAccount)

        let username = usernameData.flatMap { String(data: $0, encoding: .utf8) }
        let email = emailData.flatMap { String(data: $0, encoding: .utf8) }
        return (username, email)
    }

    func clearUserInfo() {
        let _ = KeychainHelper.shared.delete(service: userInfoService, account: usernameAccount)
        let _ = KeychainHelper.shared.delete(service: userInfoService, account: emailAccount)
    }
    */

    // MARK: - Registration and Login (Not needed for anonymous token flow)
    /*
    func register(username: String, password: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://crowdsense-9jqz.onrender.com/register/") else {
            completion(false)
            return
        }
        // Prepare the JSON body with username and password, etc.
    }
    
    func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://crowdsense-9jqz.onrender.com/api-token-auth/") else {
            completion(false)
            return
        }
        // JSON body, send login request, and handle token storage...
    }
    
    func updateUserEmail(newEmail: String, completion: @escaping (Bool) -> Void) {
        // Function for updating user email.
    }
    
    func fetchEmail(completion: @escaping (String?) -> Void) {
        // Function for fetching user email.
    }
    */

    // MARK: - Anonymous Token Support

    /// Returns an anonymous token.
    /// If a token already exists, it returns that token.
    /// Otherwise, it generates a new token, saves it, and returns it.
    func getAnonymousToken() -> String? {
        if let token = getToken() {
            return token
        } else {
            let token = UUID().uuidString
            guard let tokenData = token.data(using: .utf8) else { return nil }
            let saved = KeychainHelper.shared.save(tokenData, service: service, account: account)
            if saved {
                return token
            }
            return nil
        }
    }
    
    /// Checks whether a token exists (i.e., if the user is "logged in" anonymously).
    func isLoggedIn() -> Bool {
        return getAnonymousToken() != nil
    }

    /// Logs out by clearing the token.
    func logout() {
        let _ = KeychainHelper.shared.delete(service: service, account: account)
    }
    
    /// Retrieves the token from Keychain if it exists.
    private func getToken() -> String? {
        if let tokenData = KeychainHelper.shared.retrieve(service: service, account: account),
           let token = String(data: tokenData, encoding: .utf8) {
            return token
        }
        return nil
    }
    
    // MARK: - Authenticated Requests

    /// Example: Make an authenticated request.
    func makeAuthenticatedRequest(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        guard let url = URL(string: "https://crowdsense-9jqz.onrender.com\(endpoint)") else {
            completion(nil, nil, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Attach token if we have it.
        if let token = getToken() {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        URLSession.shared.dataTask(with: request, completionHandler: completion).resume()
    }
}
