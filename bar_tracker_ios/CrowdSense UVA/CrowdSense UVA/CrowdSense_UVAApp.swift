//
//  CrowdSense_UVAApp.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/12/25.
//

import SwiftUI

@main
struct CrowdSense_UVAApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var barListViewModel = BarListViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authVM.isAuthenticated {
                SplashView()
                    .environmentObject(barListViewModel)
                    .environmentObject(locationManager)
                    .environmentObject(authVM)
            } 
        }
    }
}
