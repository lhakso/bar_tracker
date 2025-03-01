//
//  BarLocation.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 3/1/25.
//

import Foundation

struct BarLocation: Codable {
    let id: Int      // Or UUID if preferred
    let latitude: Float
    let longitude: Float
}
