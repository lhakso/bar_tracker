//
//  AuthViewModel.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/17/25.
//

import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var user: String = ""
    @Published var email : String = ""
    
    init() {
        isAuthenticated = AuthService.shared.isLoggedIn()
        if isAuthenticated {
            let userInfo = AuthService.shared.getUserInfo()
            user = userInfo.username ?? ""
            email = userInfo.email ?? ""
        }
    }
    
    func updateEmail(newEmail: String, completion: @escaping (Bool) -> Void) {
        AuthService.shared.updateUserEmail(newEmail: newEmail) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.email = newEmail
                    AuthService.shared.fetchEmail { email in
                        DispatchQueue.main.async {
                            if let email = email {
                                self?.email = email
                            } else {
                                print("Failed to fetch email")
                            }
                            
                            completion(success)
                        }
                    }
                }
            }
        }
    }

    func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
        AuthService.shared.login(username: username, password: password) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthenticated = true
                    self?.user = username
                }
                completion(success)
            }
        }
    }
    
    func logout() {
        AuthService.shared.logout()
        isAuthenticated = false
    }
}
