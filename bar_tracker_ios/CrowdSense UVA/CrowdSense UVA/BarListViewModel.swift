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
                    self.bars = decodedBars.filter { $0.isActive }.sorted { $0.id < $1.id }
                    let newBarLocations = self.bars.map { bar in
                        BarLocation(id: bar.id, latitude: Float(bar.latitude), longitude: Float(bar.longitude))
                    }
                    populateBarsNameDict(with: self.bars)
                    BarLocationDataStore.shared.save(locations: newBarLocations)
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
            }
        }
    }
    // Submit occupancy data to the backend
    func submitOccupancy(
        barId: Int,
        occupancy: Int,
        lineWait: Int,
        completion: @escaping (Bool) -> Void
    ) {
        APIService.shared.submitOccupancy(barId: barId, occupancy: occupancy, lineWait: lineWait) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    // Optionally refresh bar data
                    self.fetchBars()
                    completion(success)
                case .failure(let error):
                    print("Failed to submit occupancy: \(error.localizedDescription)")
                    completion(false)
                }
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
public struct Bar: Identifiable, Decodable {
    public let id: Int
    public let name: String
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
// Create a public dictionary for ID-based lookups
public var barDictionary: [Int: String] = [:]

// Function to populate the dictionary with bars
public func populateBarsNameDict(with bars: [Bar]) {
    barDictionary = Dictionary(uniqueKeysWithValues: bars.map { ($0.id, $0.name) })
}

// Function to lookup a bar by ID
public func getBar(withId id: Int) -> String? {
    return barDictionary[id]
}
