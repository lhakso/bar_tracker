import Foundation

class BarLocationDataStore {
    static let shared = BarLocationDataStore()
    private let fileURL: URL

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent("barLocations.json")
    }

    func save(locations: [BarLocation]) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(locations)
            try data.write(to: fileURL)
            print("Bar locations saved successfully.")
        } catch {
            print("Error saving bar locations: \(error)")
        }
    }

    func load() -> [BarLocation]? {
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: fileURL)
            let locations = try decoder.decode([BarLocation].self, from: data)
            return locations
        } catch {
            print("Error loading bar locations: \(error)")
            return nil
        }
    }
}
