import CoreLocation
import SwiftUI
import UserNotifications

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    static let shared = LocationManager()
    @Published var lastLocation: CLLocation?
    @Published var userIsNearBar: Int? = nil
    var authorizationCallback: ((CLAuthorizationStatus) -> Void)?
    
    // Constants for geofence settings
    private let barProximityRadius = 30.0 // meters - radius around each bar to detect proximity
    
    private var locationRequestCompletion: ((CLLocation?) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        
        // Request notification permissions for debugging
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            print("Notification permission granted: \(granted)")
        }
    }
    
    func startLocationServices() {
        // Configure for background updates
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        
        // Set up individual bar geofences
        setupBarGeofences()
        
        sendDebugNotification(message: "Location services started with bar geofences")
    }
    
    // Set up geofences for individual bars
    private func setupBarGeofences() {
        guard let barLocations = BarLocationDataStore.shared.load(), !barLocations.isEmpty else {
            print("No bar locations available to set up geofences")
            return
        }
        
        // First, clear any existing geofences
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        
        // Create a geofence for each bar
        for bar in barLocations {
            let barCoordinate = CLLocationCoordinate2D(
                latitude: CLLocationDegrees(bar.latitude),
                longitude: CLLocationDegrees(bar.longitude)
            )
            
            let barRegion = CLCircularRegion(
                center: barCoordinate,
                radius: barProximityRadius, // Use meters directly
                identifier: "Bar-\(bar.id)"
            )
            barRegion.notifyOnEntry = true
            barRegion.notifyOnExit = true
            
            manager.startMonitoring(for: barRegion)
            print("Started monitoring region for bar #\(bar.id)")
        }
        
        sendDebugNotification(message: "Set up \(barLocations.count) bar geofences")
        
        // Request current location to check if already in any bar region
        manager.requestLocation()
    }
    
    func getAuthorizationStatus() -> CLAuthorizationStatus {
        return manager.authorizationStatus
    }
    
    // For debugging: Send a local notification to verify updates
    private func sendDebugNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Location Update"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationCallback?(manager.authorizationStatus)
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            print("Granted 'While Using', now requesting 'Always Allow'")
            requestAlwaysAuthorization()
        case .authorizedAlways:
            print("Granted Always Allow")
            startLocationServices()
            sendDebugNotification(message: "Always permission granted")
        case .denied, .restricted:
            print("Location access denied")
            sendDebugNotification(message: "Location access denied")
        case .notDetermined:
            print("Location permission not requested yet")
        @unknown default:
            break
        }
    }
    
    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }
    
    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        locationRequestCompletion = completion
        manager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        lastLocation = newLocation
        print("Location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        
        // Check if current location is inside any bar region
        // This is only used when we get a location update (like after setup) to initialize state
        if let barLocations = BarLocationDataStore.shared.load(), !barLocations.isEmpty {
            var nearestBarId: Int? = nil
            var nearestDistance = Double.greatestFiniteMagnitude
            
            for bar in barLocations {
                let barLocation = CLLocation(
                    latitude: CLLocationDegrees(bar.latitude),
                    longitude: CLLocationDegrees(bar.longitude)
                )
                
                let distance = newLocation.distance(from: barLocation)
                if distance <= barProximityRadius && distance < nearestDistance {
                    nearestDistance = distance
                    nearestBarId = bar.id
                }
            }
            
            // Update if we found a bar we're in
            if let barId = nearestBarId, userIsNearBar != barId {
                // Check for token before updating
                guard AuthService.shared.getAnonymousToken() != nil else {
                    print("WARNING: No valid auth token available for initial location update")
                    return
                }
                
                DispatchQueue.main.async {
                    self.userIsNearBar = barId
                    self.updateUserIsNearBar(nearBarId: barId)
                }
                print("Initial location is near bar #\(barId)")
                sendDebugNotification(message: "Initial location near bar #\(barId)")
            }
        }
        
        // Call the completion handler if it exists
        locationRequestCompletion?(newLocation)
        locationRequestCompletion = nil
    }
    
    // Handle region events for individual bars
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier.starts(with: "Bar-") {
            // Extract bar ID from the region identifier (format: "Bar-{id}")
            if let barIdString = region.identifier.split(separator: "-").last,
               let barId = Int(barIdString) {
                print("🍻 ENTERED BAR #\(barId) REGION")
                sendDebugNotification(message: "Entered bar #\(barId)")
                
                // Check for token before updating
                guard AuthService.shared.getAnonymousToken() != nil else {
                    print("WARNING: No valid auth token available for bar region update")
                    return
                }
                
                // Update the published property and send API update
                DispatchQueue.main.async {
                    self.userIsNearBar = barId
                    self.updateUserIsNearBar(nearBarId: barId)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier.starts(with: "Bar-") {
            if let barIdString = region.identifier.split(separator: "-").last,
               let barId = Int(barIdString) {
                print("↓ EXITED BAR #\(barId) REGION")
                sendDebugNotification(message: "Left bar #\(barId)")
                
                // Check for token before updating
                guard AuthService.shared.getAnonymousToken() != nil else {
                    print("WARNING: No valid auth token available for bar region update")
                    return
                }
                
                // Only clear if this is the current bar
                if self.userIsNearBar == barId {
                    DispatchQueue.main.async {
                        self.userIsNearBar = nil
                        self.updateUserIsNearBar(nearBarId: nil)
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        sendDebugNotification(message: "Location error: \(error.localizedDescription)")
        locationRequestCompletion?(nil)
        locationRequestCompletion = nil
    }
    
    func ensureRegionMonitoringActive() {
        // Check if we're already monitoring any bar regions
        var isMonitoringAnyBar = false
        for region in manager.monitoredRegions {
            if region.identifier.starts(with: "Bar-") {
                isMonitoringAnyBar = true
                break
            }
        }
        
        // If not monitoring any bars, set them up
        if !isMonitoringAnyBar {
            setupBarGeofences()
        }
        
        print("Region monitoring status checked and ensured active")
    }
    
    // Refresh location state based on current location
    func refreshLocationState() {
        // Request current location to evaluate position relative to bars
        manager.requestLocation()
        print("Location state refresh requested")
    }
    
    private func computeProximity(for barLocation: BarLocation, with location: CLLocation, thresholdMiles: Double) -> Bool {
        let barCLLocation = CLLocation(latitude: CLLocationDegrees(barLocation.latitude),
                                       longitude: CLLocationDegrees(barLocation.longitude))
        let distanceInMiles = location.distance(from: barCLLocation) / 1609.34
        return distanceInMiles <= thresholdMiles
    }
    
    // Maintained for backward compatibility
    func checkAndUpdateUserProximity(barLocation: BarLocation, thresholdMiles: Double = 0.01, completion: @escaping (Bool) -> Void) {
        // If we're already tracking this bar via geofence, use that
        if userIsNearBar == barLocation.id {
            completion(true)
            return
        }
        
        // Otherwise, use the legacy distance calculation
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
    
    // This is maintained for backward compatibility with any submission code
    func checkUserProximityForSubmission(barLocation: BarLocation, thresholdMiles: Double = 0.03, completion: @escaping (Bool) -> Void) {
        // If we're already tracking this bar via geofence, use that
        if userIsNearBar == barLocation.id {
            completion(true)
            return
        }
        
        // Otherwise calculate distance
        if let location = lastLocation {
            let barCLLocation = CLLocation(
                latitude: CLLocationDegrees(barLocation.latitude),
                longitude: CLLocationDegrees(barLocation.longitude)
            )
            let distanceInMiles = location.distance(from: barCLLocation) / 1609.34
            completion(distanceInMiles <= thresholdMiles)
        } else {
            requestLocation { [weak self] newLocation in
                guard let self = self, let location = newLocation else {
                    completion(false)
                    return
                }
                
                let barCLLocation = CLLocation(
                    latitude: CLLocationDegrees(barLocation.latitude),
                    longitude: CLLocationDegrees(barLocation.longitude)
                )
                let distanceInMiles = location.distance(from: barCLLocation) / 1609.34
                completion(distanceInMiles <= thresholdMiles)
            }
        }
    }
    
    // For updating the server
    func updateUserIsNearBar(nearBarId: Int?) {
        var body: [String: Any] = [:]
        
        if let barId = nearBarId {
            body["near_bar_id"] = barId
            print("Setting near_bar_id to \(barId)")
        } else {
            body["near_bar_id"] = -1
            print("Setting near_bar_id to -1")
        }

        // RIGHT BEFORE the request is sent
        print("FINAL REQUEST BODY: \(body)")
        AuthService.shared.makeAuthenticatedRequest(endpoint: "is_near_bar/", method: "POST", body: body) { data, response, error in
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
    
    // Add a method to refresh bar geofences if they change
    func refreshBarGeofences() {
        setupBarGeofences()
    }
    
    // Legacy method for backward compatibility
    func updateProximityToAnyBar(locations: [BarLocation], completion: @escaping (Int?) -> Void) {
        // If we already have a bar from geofencing, return that
        if let currentBarId = userIsNearBar {
            completion(currentBarId)
            return
        }
        
        // Otherwise use the legacy approach
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
}
