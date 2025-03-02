// AppDelegate.swift
import UIKit
import SwiftUI
import CoreLocation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // If app was launched from background due to location event
        if launchOptions?[UIApplication.LaunchOptionsKey.location] != nil {
            print("App launched from location update")
            LocationManager.shared.startLocationServices()
        }
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entering background - ensuring location services")
        LocationManager.shared.startSignificantLocationMonitoring()
    }
}
