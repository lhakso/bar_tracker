import SwiftUI
import Combine

class BarListViewModel: ObservableObject {
    @Published var bars: [Bar] = []
    @Published var userLocation: Location? // To store the user's current location

    // Fetch bar data from the backend
    func fetchBars() {
        print("fetchBars called")
        guard let url = URL(string: "http://127.0.0.1:8000/bars/") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
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
                    self.bars = decodedBars.filter { $0.isActive } // Show only active bars
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // Submit occupancy data to the backend
    func submitOccupancy(barId: Int, occupancy: Int, lineWait: Int) {
        guard let url = URL(string: "http://127.0.0.1:8000/submit_occupancy/") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "bar_id": barId,
            "occupancy_level": occupancy,
            "line_wait": lineWait
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error submitting occupancy: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data returned")
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("Response from server: \(responseString)")
            }
        }.resume()
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
