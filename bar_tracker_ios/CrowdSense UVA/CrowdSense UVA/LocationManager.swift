//
//  LocationManager.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/26/25.
//

import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // Reference to your BarListViewModel (or any VM that has getUserLocation())
    var barListViewModel: BarListViewModel?
    
    override init() {
        super.init()
        
        // Set delegate and request authorization
        locationManager.delegate = self
        
        // Request 'always' or 'when in use' authorization, depending on your needs
        locationManager.requestAlwaysAuthorization()
        
        // Start monitoring significant location changes
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    // Delegate callback for location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Whenever a location update triggers, call getUserLocation on your VM
        barListViewModel?.getUserLocation()
    }
    
    // Error handling if needed
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Significant location updates failed with error: \(error)")
    }
}
