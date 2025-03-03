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

    func saveUserInfo(username: String) {
        let _ = KeychainHelper.shared.save(username.data(using: .utf8)!, service: userInfoService, account: usernameAccount)
    }
   
    func register(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://crowdsense-9jqz.onrender.com/register/") else {
            completion(false)
            return
        }

        guard let token = getAnonymousToken() else {
            print("Failed to retrieve anonymous token.")
            completion(false)
            return
        }

        let bodyDict: [String: Any] = ["user": token]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict, options: []) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Registration error:", error)
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("Registration successful with token:", token)
                completion(true)
            } else {
                print("Registration failed, response:", response ?? "No response")
                completion(false)
            }
        }.resume()
    }
    /// Returns an anonymous token.
    /// If a token already exists, it returns that token.
    /// Otherwise, it generates a new token, saves it, and returns it.
    func getAnonymousToken() -> String? {
        // Try to get existing token
        if let token = getToken() {
            return token
        }
        
        // Create a new token (avoid calling this from background processes)
        let token = UUID().uuidString
        guard let tokenData = token.data(using: .utf8) else { return nil }
        let saved = KeychainHelper.shared.save(tokenData, service: service, account: account)
        return saved ? token : nil
    }
    
    /// Checks whether a token exists (i.e., if the user is "logged in" anonymously).
    func isLoggedIn() -> Bool {
        return getAnonymousToken() != nil
    }

    /// Logs out by clearing the token.
    func logout() {
        let _ = KeychainHelper.shared.delete(service: service, account: account)
    }
    
    // In AuthService.swift, make getToken public and consistent:
    func getToken() -> String? {
        print("Attempting to retrieve token for background request")
        if let tokenData = KeychainHelper.shared.retrieve(service: service, account: account),
           let token = String(data: tokenData, encoding: .utf8) {
            print("Successfully retrieved token: \(token.prefix(8))...")
            return token
        }
        print("❌ Failed to retrieve token from keychain")
        return nil
    }
    
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
            request.setValue("\(token)",forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        URLSession.shared.dataTask(with: request, completionHandler: completion).resume()
    }
}
