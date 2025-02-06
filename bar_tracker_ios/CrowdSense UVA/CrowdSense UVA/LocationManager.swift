import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    // Store the user's last known location
    @Published var lastLocation: CLLocation?
    @Published var userIsNearBar: Bool = false
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

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    func isUserNearBar(barLat: Double, barLon: Double, threshHoldMiles: Double=0.03, bar: Bar)-> Bool{
        let barLocation = CLLocation(latitude: bar.latitude, longitude: bar.longitude)
        guard let userLocation = lastLocation else { return false }
        let distanceInMiles = userLocation.distance(from: barLocation) / 1609.34
        let isNear = distanceInMiles <= 0.03

        DispatchQueue.main.async { self.userIsNearBar = isNear }
        return isNear
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
