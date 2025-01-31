import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    // Store the user's last known location
    @Published var lastLocation: CLLocation?

    override init() {
           super.init()
           manager.delegate = self
           manager.desiredAccuracy = kCLLocationAccuracyBest

           // First, request When In Use authorization
           if manager.authorizationStatus == .notDetermined {
               manager.requestWhenInUseAuthorization()
           } else if manager.authorizationStatus == .authorizedWhenInUse {
               // If already "When In Use", request "Always Allow"
               manager.requestAlwaysAuthorization()
           }

           manager.startUpdatingLocation()
       }
    func requestSingleLocation() {
        manager.requestLocation()  // Triggers a one-time location check
    }
    func requestAlwaysPermission() {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()  // ✅ Requests "Always Allow" when possible
        }
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
        // Keep track of the newest location
        lastLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}
