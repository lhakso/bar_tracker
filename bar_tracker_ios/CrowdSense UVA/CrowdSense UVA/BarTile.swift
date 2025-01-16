//
//  BarTile.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/14/25.
//

import SwiftUI

struct BarTile: View {
    let bar: Bar

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Bar Name
            Text(bar.name)
                .font(.title2) // Larger font for the name
                .foregroundColor(.white)

            // Occupancy and Line Wait
            HStack {
                Text("Occupancy: \(bar.occupancy)")
                    .font(.subheadline)
                Spacer()
                Text("Line Wait: \(bar.lineWait)")
                    .font(.subheadline)
            }
            //.foregroundColor(.gray)
            .foregroundColor(.white.opacity(0.85))
        }
        .padding() // Add internal padding
        .frame(maxWidth: .infinity, minHeight: 170) // Set height for each tile
        .background(
            //Color(red: 230/255, green: 235/255, blue: 245/255) // Light blue background
            Color(red: 40/255, green: 50/255, blue: 100/255) //dark blue
               )
        .cornerRadius(20) // Rounded corners
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2) // Optional: Add a shadow
    }
}
