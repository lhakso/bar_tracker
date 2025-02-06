import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    static let shared = LocationManager()
    @Published var lastLocation: CLLocation?
    @Published var userIsNearBar: Bool = false
    
    private var locationRequestCompletion: ((CLLocation?) -> Void)?

    
    override init() {
           super.init()
           manager.delegate = self
           manager.desiredAccuracy = kCLLocationAccuracyBest
           manager.startUpdatingLocation()
       }

       func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
           switch manager.authorizationStatus {
           case .authorizedWhenInUse:
               print("Granted 'While Using', now requesting 'Always Allow'")
               manager.requestAlwaysAuthorization()  // request always after while using
           case .authorizedAlways:
               print("Granted Always Allow")
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
        locationRequestCompletion?(newLocation)
        locationRequestCompletion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        locationRequestCompletion?(nil)
        locationRequestCompletion = nil
    }
    
    private func computeProximity(for bar: Bar, with location: CLLocation, threshHoldMiles: Double) -> Bool {
        let barLocation = CLLocation(latitude: bar.latitude, longitude: bar.longitude)
        let distanceInMiles = location.distance(from: barLocation) / 1609.34
        return distanceInMiles <= threshHoldMiles
    }
    
    func checkAndUpdateUserProximity(threshHoldMiles: Double = 5.03, bar: Bar, completion: @escaping (Bool) -> Void) {
            // if have a lastLocation use it
            if let location = lastLocation {
                let isNear = computeProximity(for: bar, with: location, threshHoldMiles: threshHoldMiles)
                updateUserIsNearBar(isNearBar: isNear)
                DispatchQueue.main.async { self.userIsNearBar = isNear }
                completion(isNear)
            } else {
                // else request a location update and then perform the check
                requestLocation { [weak self] newLocation in
                    guard let self = self, let location = newLocation else {
                        completion(false)
                        return
                    }
                    self.lastLocation = location  // update the stored location
                    let isNear = self.computeProximity(for: bar, with: location, threshHoldMiles: threshHoldMiles)
                    self.updateUserIsNearBar(isNearBar: isNear)
                    DispatchQueue.main.async { self.userIsNearBar = isNear }
                    completion(isNear)
                }
            }
        }
    
    func updateUserIsNearBar(isNearBar: Bool) {
            let body: [String: Any] = ["is_near_bar": isNearBar]

        AuthService.shared.makeAuthenticatedRequest(endpoint: "/is_near_bar/", method: "POST", body: body) { data, response, error in
                if let error = error {
                    print("Error updating is_near_bar: \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Successfully updated is_near_bar")
                } else {
                    print("Failed to update is_near_bar")
                }
            }
        }

}
