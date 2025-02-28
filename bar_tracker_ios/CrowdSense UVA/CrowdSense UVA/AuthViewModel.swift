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
    //@Published var email : String = ""
    @Published var anonymousToken: String = ""
    
    init() {
        if let token = AuthService.shared.getAnonymousToken() {
            print("ran get anon token from authviewmodel, token is: \(token)")
            self.user = token
            // Call register to ensure the backend has this user registered.
            // This will either create a new user or do nothing if the user already exists.
            AuthService.shared.register { success in
                DispatchQueue.main.async {
                    self.isAuthenticated = success
                }
            }
        } else {
            self.isAuthenticated = false
        }
    }
}
