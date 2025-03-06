// AppDelegate.swift
import UIKit
import SwiftUI
import CoreLocation
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // If app was launched from background due to location event
        if launchOptions?[UIApplication.LaunchOptionsKey.location] != nil {
            print("App launched from location update")
            
            // Request notification permissions for debug purposes
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                print("Notification permission on launch: \(granted)")
            }
            
            // Send debug notification
            let content = UNMutableNotificationContent()
            content.title = "App Launch"
            content.body = "App launched due to location event"
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
            
            // Start location services
            LocationManager.shared.startLocationServices()
        }
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entering background - ensuring location services")
        
        // Make sure region monitoring is active when going to background
        if LocationManager.shared.getAuthorizationStatus() == .authorizedAlways {
            // This ensures geofencing is active even if the app was in foreground before
            LocationManager.shared.ensureRegionMonitoringActive()
        }
    }
    
    // Handle when app becomes active
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App became active")
        
        // Check current location to update state if needed
        LocationManager.shared.refreshLocationState()
    }
}
