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
    
    /// Register a new user with the backend.
    func register(username: String, password: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://crowdsense-9jqz.onrender.com/register/") else {
            completion(false)
            return
        }

        // Prepare the JSON body with username and password
        let bodyDict = ["username": username, "password": password]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict, options: []) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        // Send the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse, response.statusCode == 201 else {
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    func updateUserEmail(newEmail: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://crowdsense-9jqz.onrender.com/update_email/") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Attach token
        if let token = AuthService.shared.getToken() {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = ["email": newEmail]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating email:", error)
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
    
    func fetchEmail(completion: @escaping (String?) -> Void) {
        let endpoint = "/get_email/"
        AuthService.shared.makeAuthenticatedRequest(endpoint: endpoint, method: "GET", body: nil) { data, response, error in
            if let error = error {
                print("Error fetching email:", error)
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let email = json["email"] as? String {
                    completion(email)
                } else {
                    print("Invalid JSON response or missing 'email' key")
                    completion(nil)
                }
            } catch {
                print("JSON parsing error:", error)
                completion(nil)
            }
        }
    }

    /// Attempt to log in by sending username/password to your Django DRF token endpoint.
    func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://crowdsense-9jqz.onrender.com/api-token-auth/") else {
            completion(false)
            return
        }

        // JSON body
        let bodyDict = ["username": username, "password": password]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict, options: []) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("Login error:", error)
                completion(false)
                return
            }

            guard let data = data else {
                print("No data received during login")
                completion(false)
                return
            }

            // Example JSON response: {"token":"<your_token_here>"}
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String,
                   let tokenData = token.data(using: .utf8) {

                    // Save token to Keychain
                    let tokenSaved = KeychainHelper.shared.save(tokenData, service: self.service, account: self.account)

                    // Save username to Keychain
                    self.saveUserInfo(username: username)

                    if tokenSaved {
                        DispatchQueue.main.async {
                            print("Login successful for user: \(username)")
                            completion(true)
                        }
                    } else {
                        print("Failed to save token to Keychain")
                        completion(false)
                    }
                } else {
                    print("Invalid JSON response or missing keys")
                    completion(false)
                }
            } catch {
                print("JSON parsing error:", error)
                completion(false)
            }
        }.resume()
    }

    /// Check if we already have a token (simple memory check here).
    func isLoggedIn() -> Bool {
        guard let _ = getToken() else { return false }
        return true
    }

    /// Log out by clearing the token.
    func logout() {
        let _ = KeychainHelper.shared.delete(service: service, account: account)
    }
    private func getToken() -> String? {
        if let tokenData = KeychainHelper.shared.retrieve(service: service, account: account),
           let token = String(data: tokenData, encoding: .utf8) {
            return token
        }
        return nil
    }
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

        // Attach token if we have it
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
