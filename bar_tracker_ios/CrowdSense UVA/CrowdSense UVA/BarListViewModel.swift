import SwiftUI
import Combine

class BarListViewModel: ObservableObject {
    @Published var bars: [Bar] = []
    @Published var userLocation: Location? // To store the user's current location

    // Fetch bar data from the backend
    func fetchBars() {
        AuthService.shared.makeAuthenticatedRequest(endpoint: "/bars/") { data, response, error in
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
    func submitOccupancy(barId: String, occupancy: Int, lineWait: Int, user: String, completion: @escaping (Bool) -> Void) {
        // Prepare the endpoint and payload
        let endpoint = "/submit_occupancy/"
        let payload: [String: Any] = [
            "bar_id": barId,
            "user": user,
            "occupancy_level": occupancy,
            "line_wait": lineWait
        ]
        print("payload: \(payload)")
        
        // Use the AuthService's `makeAuthenticatedRequest`
        AuthService.shared.makeAuthenticatedRequest(endpoint: endpoint, method: "POST", body: payload) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                completion(false)
                return
            }
            self.fetchBars()
            
            completion(true)
            if let httpResponse = response as? HTTPURLResponse {
                print("Status code: \(httpResponse.statusCode)")
            }

        }
    }




    // Fetch user location from the backend
    func getUserLocation() {
        guard let url = URL(string: "http://127.0.0.1:8000/get_location/") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching user location: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data returned")
                return
            }
            do {
                let decodedLocation = try JSONDecoder().decode(Location.self, from: data)
                DispatchQueue.main.async {
                    self.userLocation = decodedLocation
                }
            } catch {
                print("Error decoding location JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
}

// Location structure to decode the response from get-location API
struct Location: Decodable {
    let latitude: Double
    let longitude: Double
}

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
