import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    static let shared = LocationManager()
    @Published var lastLocation: CLLocation?
    @Published var userIsNearBar: Int? = nil
    
    private var locationRequestCompletion: ((CLLocation?) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Request permissions when initialized
        manager.requestWhenInUseAuthorization()
    }
    
    func startSignificantLocationMonitoring() {
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            manager.startMonitoringSignificantLocationChanges()
            print("Started significant location monitoring")
        }
    }
    
    func startLocationServices() {
        // Allow the app to receive location updates in the background
        manager.allowsBackgroundLocationUpdates = true
        
        // Start regular location updates
        manager.startUpdatingLocation()
        print("Started regular location updates with background capability")
        
        // Add significant location monitoring for background wake-ups
        startSignificantLocationMonitoring()
        
        // Optional: allow system to pause updates when stationary to save battery
        manager.pausesLocationUpdatesAutomatically = true
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            print("Granted 'While Using', now requesting 'Always Allow'")
            manager.requestAlwaysAuthorization()  // request always after while using
        case .authorizedAlways:
            print("Granted Always Allow")
            startLocationServices()  // Start all location services once we have "Always" permission
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            print("Location permission not requested yet")
        @unknown default:
            break
        }
    }
    
    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        self.locationRequestCompletion = completion
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        lastLocation = newLocation
        print("Location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        
        // First check if we have a valid token before proceeding
        guard let token = AuthService.shared.getAnonymousToken() else {
            print("WARNING: No valid auth token available for background location update")
            // Don't attempt the API call without a token
            return
        }
        print("Valid token available for background location update: \(token.prefix(6))...")
        
        if let storedLocations = BarLocationDataStore.shared.load(), !storedLocations.isEmpty {
            updateProximityToAnyBar(locations: storedLocations) { [weak self] nearBarId in
                DispatchQueue.main.async {
                    self?.userIsNearBar = nearBarId
                    
                    // Log the near_bar_id value before the API call
                    print("About to update near_bar_id: \(nearBarId ?? -100)")
                    
                    // Only make the API call if we have a valid token
                    self?.updateUserIsNearBar(nearBarId: nearBarId)
                }
                if let barId = nearBarId {
                    print("User is near bar with id: \(barId)")
                } else {
                    print("User is not near any bar.")
                }
            }
        } else {
            print("No bar locations available for proximity check.")
        }
        
        locationRequestCompletion?(newLocation)
        locationRequestCompletion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        locationRequestCompletion?(nil)
        locationRequestCompletion = nil
    }
    
    private func computeProximity(for barLocation: BarLocation, with location: CLLocation, thresholdMiles: Double) -> Bool {
        let barCLLocation = CLLocation(latitude: CLLocationDegrees(barLocation.latitude),
                                       longitude: CLLocationDegrees(barLocation.longitude))
        let distanceInMiles = location.distance(from: barCLLocation) / 1609.34
        return distanceInMiles <= thresholdMiles
    }
    
    func checkAndUpdateUserProximity(barLocation: BarLocation, thresholdMiles: Double = 0.03, completion: @escaping (Bool) -> Void) {
        if let location = lastLocation {
            let isNear = computeProximity(for: barLocation, with: location, thresholdMiles: thresholdMiles)
            completion(isNear)
        } else {
            requestLocation { [weak self] newLocation in
                guard let self = self, let location = newLocation else {
                    completion(false)
                    return
                }
                self.lastLocation = location
                let isNear = self.computeProximity(for: barLocation, with: location, thresholdMiles: thresholdMiles)
                completion(isNear)
            }
        }
    }
    
    func updateProximityToAnyBar(locations: [BarLocation], completion: @escaping (Int?) -> Void) {
        let group = DispatchGroup()
        var nearBarId: Int? = nil
        
        for barLocation in locations {
            group.enter()
            checkAndUpdateUserProximity(barLocation: barLocation) { isNear in
                if isNear && nearBarId == nil {
                    nearBarId = barLocation.id
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(nearBarId)
        }
    }
    
    func updateUserIsNearBar(nearBarId: Int?) {
        var body: [String: Any] = [:]
        
        // If nearBarId is not nil, add it to the body; otherwise, send NSNull()
        print("nearBarId: \(nearBarId ?? -100)")
        if let barId = nearBarId {
            body["near_bar_id"] = barId
            print("Setting near_bar_id to \(barId)")
        } else {
            body["near_bar_id"] = -1
            print("Setting near_bar_id to -1")
        }

        // RIGHT BEFORE the request is sent
        print("FINAL REQUEST BODY: \(body)")
        AuthService.shared.makeAuthenticatedRequest(endpoint: "/is_near_bar/", method: "POST", body: body) { data, response, error in
            if let error = error {
                print("Error updating near_bar_id: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Successfully updated near_bar_id")
            } else {
                print("Failed to update near_bar_id")
            }
        }
    }
}
