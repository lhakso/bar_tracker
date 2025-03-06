import CoreLocation
import SwiftUI
import UserNotifications

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    static let shared = LocationManager()
    @Published var lastLocation: CLLocation?
    @Published var userIsNearBar: Int? = nil
    private var isUsingPreciseLocationUpdates = false
    var authorizationCallback: ((CLAuthorizationStatus) -> Void)?
    
    // Define the rough boundary of the bar district
    private let barAreaCenter = CLLocation(latitude: 38.03519157104836, longitude: -78.50011168821909)
    private let barAreaRadius = 100.4 // miles (broad area containing all bars)
    
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
        
        // Set up and start monitoring the bar district region
        setupBarRegionMonitoring()
        
        sendDebugNotification(message: "Location services started with geofence monitoring")
    }
    
    // Set up geofence for the bar area
    private func setupBarRegionMonitoring() {
        let barRegion = CLCircularRegion(
            center: barAreaCenter.coordinate,
            radius: barAreaRadius * 1609.34, // Convert miles to meters
            identifier: "BarDistrictRegion"
        )
        barRegion.notifyOnEntry = true
        barRegion.notifyOnExit = true
        
        // Stop any existing monitoring first
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        
        manager.startMonitoring(for: barRegion)
        print("Started monitoring bar region with geofence")
        
        // Request current location to check if already in region
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
    
    // Check if user is in the general bar area
    private func checkIfInBarArea(_ location: CLLocation) {
        let distanceInMiles = location.distance(from: barAreaCenter) / 1609.34
        let isInArea = distanceInMiles <= barAreaRadius
        print("📍 Distance to bar area: \(distanceInMiles) miles, threshold: \(barAreaRadius) miles, isInArea: \(isInArea)")
        
        // Initial state setup if needed
        if isInArea && !isUsingPreciseLocationUpdates {
            print("Already in bar area, starting precise updates")
            startPreciseUpdates()
        }
    }
    
    // Start precise location tracking
    private func startPreciseUpdates() {
        if !isUsingPreciseLocationUpdates {
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 10 // meters
            manager.startUpdatingLocation()
            isUsingPreciseLocationUpdates = true
            sendDebugNotification(message: "Started precise location tracking")
        }
    }
    
    // Stop precise location tracking
    private func stopPreciseUpdates() {
        if isUsingPreciseLocationUpdates {
            manager.stopUpdatingLocation()
            isUsingPreciseLocationUpdates = false
            sendDebugNotification(message: "Stopped precise location tracking")
        }
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
        self.locationRequestCompletion = completion
        manager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        lastLocation = newLocation
        print("Location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        
        // Check if in bar area on first location
        if !isUsingPreciseLocationUpdates {
            checkIfInBarArea(newLocation)
        }
        
        // Check for proximity to specific bars only when in bar area with precise updates
        if isUsingPreciseLocationUpdates {
            // Check for token and process bar proximity
            guard AuthService.shared.getAnonymousToken() != nil else {
                print("WARNING: No valid auth token available for location update")
                return
            }
            
            if let storedLocations = BarLocationDataStore.shared.load(), !storedLocations.isEmpty {
                updateProximityToAnyBar(locations: storedLocations) { [weak self] nearBarId in
                    DispatchQueue.main.async {
                        self?.userIsNearBar = nearBarId
                        self?.updateUserIsNearBar(nearBarId: nearBarId)
                        
                        // Debug notification
                        if let barId = nearBarId {
                            self?.sendDebugNotification(message: "Near bar #\(barId)")
                        }
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
        }
        
        locationRequestCompletion?(newLocation)
        locationRequestCompletion = nil
    }
    
    // Handle region events
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "BarDistrictRegion" {
            print("🎯 ENTERED BAR DISTRICT REGION")
            sendDebugNotification(message: "Entered bar district")
            startPreciseUpdates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == "BarDistrictRegion" {
            print("↓ EXITED BAR DISTRICT REGION")
            sendDebugNotification(message: "Left bar district")
            stopPreciseUpdates()
            // Clear near bar state when leaving the area
            DispatchQueue.main.async {
                self.userIsNearBar = nil
                self.updateUserIsNearBar(nearBarId: nil)
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
        // Check if we're already monitoring our region
        var isMonitoringBarRegion = false
        for region in manager.monitoredRegions {
            if region.identifier == "BarDistrictRegion" {
                isMonitoringBarRegion = true
                break
            }
        }
        
        // If not monitoring, set it up
        if !isMonitoringBarRegion {
            setupBarRegionMonitoring()
        }
        
        print("Region monitoring status checked and ensured active")
    }

    // Refresh location state based on current location
    func refreshLocationState() {
        // Request current location to evaluate position relative to bar district
        manager.requestLocation()
        print("Location state refresh requested")
    }
    
    private func computeProximity(for barLocation: BarLocation, with location: CLLocation, thresholdMiles: Double) -> Bool {
        let barCLLocation = CLLocation(latitude: CLLocationDegrees(barLocation.latitude),
                                       longitude: CLLocationDegrees(barLocation.longitude))
        let distanceInMiles = location.distance(from: barCLLocation) / 1609.34
        return distanceInMiles <= thresholdMiles
    }
    
   //current threshold miles is 30ft
    func checkAndUpdateUserProximity(barLocation: BarLocation, thresholdMiles: Double = 0.01, completion: @escaping (Bool) -> Void) {
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
    
    func checkUserProximityForSubmission(barLocation: BarLocation, thresholdMiles: Double = 0.03, completion: @escaping (Bool) -> Void) {
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
