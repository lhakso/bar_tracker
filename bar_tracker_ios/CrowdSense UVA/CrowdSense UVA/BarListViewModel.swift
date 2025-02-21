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
        //user: String,
        locationManager: LocationManager,
        completion: @escaping (Bool) -> Void
    ) {
        // Prepare the endpoint and payload
        let endpoint = "/submit_occupancy/"
        let payload: [String: Any] = [
            "bar_id": barId,
            //"user": user,
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
                // fetch updated bars on the main thread
                DispatchQueue.main.async {
                    self.fetchBars()
                }
                completion(true)
            } else {
                print("Failed to submit occupancy. Status code: \(httpResponse.statusCode)")
                completion(false)
            }
        }
    }
}

// Location structure to decode the response from get-bar API
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
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case currentOccupancy = "current_occupancy"
        case currentLineWait = "current_line_wait"
        case isActive = "is_active"
        case latitude = "latitude"
        case longitude = "longitude"
    }
}
