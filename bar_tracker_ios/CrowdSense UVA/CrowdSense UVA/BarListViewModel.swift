import SwiftUI
import Combine

class BarListViewModel: ObservableObject {
    @Published var bars: [Bar] = []
    @Published var userLocation: Location? // To store the user's current location

    // Fetch bar data from the backend
    func fetchBars() {
        AuthService.shared.makeAuthenticatedRequest(endpoint: "/bars/", method: "GET", body: nil) { data, response, error in
            if let error = error {
                print("Error fetching bars: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data returned")
                return
            }

            do {
                let decoder = JSONDecoder()
                let decodedBars = try decoder.decode([Bar].self, from: data)
                DispatchQueue.main.async {
                    self.bars = decodedBars.filter { $0.isActive }
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
            }
        }
    }

    // Submit occupancy data to the backend
    func submitOccupancy(
        barId: String,
        occupancy: Int,
        lineWait: Int,
        user: String,
        locationManager: LocationManager,
        completion: @escaping (Bool) -> Void
    ) {
        // Prepare the endpoint and payload
        let endpoint = "/submit_occupancy/"
        let payload: [String: Any] = [
            "bar_id": barId,
            "user": user,
            "occupancy_level": occupancy,
            "line_wait": lineWait
        ]
        print("Submitting payload: \(payload)")

        AuthService.shared.makeAuthenticatedRequest(endpoint: endpoint, method: "POST", body: payload) { data, response, error in
            if let error = error {
                print("Error submitting occupancy: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("No valid response received.")
                completion(false)
                return
            }

            if httpResponse.statusCode == 200 {
                print("Occupancy submitted successfully.")
                
                // Fetch updated bars
                DispatchQueue.main.async {
                    self.fetchBars()
                }
                
                // Now retrieve REAL coordinates from locationManager
                DispatchQueue.main.async {
                    if let lastLocation = locationManager.lastLocation {
                        let currentLatitude = lastLocation.coordinate.latitude
                        let currentLongitude = lastLocation.coordinate.longitude

                        self.submitUserLocation(latitude: currentLatitude, longitude: currentLongitude) { locationUpdated in
                            if locationUpdated {
                                print("Location updated after submitting occupancy.")
                            } else {
                                print("Failed to update location after submitting occupancy.")
                            }
                        }
                    } else {
                        print("No user location available to update after occupancy submission.")
                    }
                }
                completion(true)
            } else {
                print("Failed to submit occupancy. Status code: \(httpResponse.statusCode)")
                completion(false)
            }
        }
    }


    // Submit user location to the backend
    func submitUserLocation(latitude: Double, longitude: Double, completion: ((Bool) -> Void)? = nil) {
        let endpoint = "/update_location/"
        let payload: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude
        ]

        AuthService.shared.makeAuthenticatedRequest(endpoint: endpoint, method: "POST", body: payload) { data, response, error in
            if let error = error {
                print("Error updating user location: \(error.localizedDescription)")
                completion?(false)
                return
            }

            guard let response = response as? HTTPURLResponse else {
                print("No valid response received for location update.")
                completion?(false)
                return
            }

            if response.statusCode == 200 {
                print("Location updated successfully!")
                completion?(true)
            } else {
                print("Failed to update location. Status code: \(response.statusCode)")
                completion?(false)
            }
        }
    }
}

// Location structure to decode the response from get-location API
struct Location: Decodable {
    let latitude: Double
    let longitude: Double
}

// Bar structure to store bar data
struct Bar: Identifiable, Decodable {
    let id: Int
    let name: String
    let currentOccupancy: Int?
    let currentLineWait: Int?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case currentOccupancy = "current_occupancy"
        case currentLineWait = "current_line_wait"
        case isActive = "is_active"
    }
}
