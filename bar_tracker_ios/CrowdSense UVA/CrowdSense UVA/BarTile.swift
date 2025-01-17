import SwiftUI

struct BarTile: View {
    let bar: Bar
    @ObservedObject var viewModel: BarListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Display bar name
            Text(bar.name)
                .font(.title2)
                .foregroundColor(.white)
            
            // Display current occupancy and line wait
            HStack {
                Text("Occupancy: \(bar.currentOccupancy ?? 0)")
                Spacer()
                Text("Line Wait: \(bar.currentLineWait ?? 0) mins")
            }
            .foregroundColor(.white.opacity(0.85))

            // Submit Button
            Button(action: {
                viewModel.submitOccupancy(barId: bar.id, occupancy: bar.currentOccupancy ?? 0, lineWait: bar.currentLineWait ?? 0)
            }) {
                Text("Submit Report")
                    .padding()
                    .frame(maxWidth: .infinity) // Stretch button width
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding() // Add internal padding
        .frame(maxWidth: .infinity, minHeight: 170) // Set height for each tile
        .background(
            // Apply a gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 40/255, green: 50/255, blue: 100/255), Color(red: 60/255, green: 70/255, blue: 120/255)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20) // Rounded corners
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2) // Optional: Add a shadow
    }
}
