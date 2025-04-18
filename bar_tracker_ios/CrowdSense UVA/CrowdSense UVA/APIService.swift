//
//  APIService.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/16/25.
//

import Foundation

struct APIService {
    private let baseURL = "https://crowdsense-9jqz.onrender.com/"
    static let shared = APIService()

    // Fetch bar data
    func fetchBars(completion: @escaping (Result<[Bar], Error>) -> Void) {
        guard let url = URL(string: baseURL + "get_bars/") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            do {
                let bars = try JSONDecoder().decode([Bar].self, from: data)
                completion(.success(bars))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Submit occupancy data
    func submitOccupancy(barId: Int, occupancy: Int, lineWait: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
         guard let url = URL(string: baseURL + "submit_occupancy/") else {
             // Create an error here if needed
             return
         }
         
         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.addValue("application/json", forHTTPHeaderField: "Content-Type")
         
         // Retrieve the token using your AuthService
         guard let token = AuthService.shared.getAnonymousToken() else {
             // Handle error if token cannot be obtained
             return
         }
         request.setValue(token, forHTTPHeaderField: "Authorization")
         
         let body: [String: Any] = [
             "bar_id": barId,
             "occupancy_level": occupancy,
             "line_wait": lineWait*5
         ]
         
         do {
             request.httpBody = try JSONSerialization.data(withJSONObject: body)
         } catch {
             completion(.failure(error))
             return
         }
         
         URLSession.shared.dataTask(with: request) { data, response, error in
             if let error = error {
                 completion(.failure(error))
                 return
             }
             
             // You can add more robust checking here based on your API's response structure
             completion(.success(true))
         }.resume()
     }
}
