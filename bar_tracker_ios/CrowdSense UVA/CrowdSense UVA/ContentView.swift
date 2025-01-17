//
//  ContentView.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/12/25.
//

import SwiftUI

struct ContentView: View {
    // ViewModel to fetch and manage data
    @StateObject private var viewModel = BarListViewModel()

    init() {
        // Customize Navigation Bar appearance to prevent transparency
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 60/255, alpha: 1) // Lighter navy
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white] // White title text
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            // Background color
            Color(red: 10/255, green: 10/255, blue: 60/255)
                .ignoresSafeArea()

            NavigationView {
                BarListView() // Using BarListView directly
                    .navigationTitle("CrowdSense")
                    .navigationBarTitleDisplayMode(.inline) // Ensures consistent title placement
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("CrowdSense")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock ViewModel for previews
        let mockViewModel = BarListViewModel()
        mockViewModel.bars = [
            Bar(id: 1, name: "Mock Bar 1", currentOccupancy: 75, currentLineWait: 5, isActive: true),
            Bar(id: 2, name: "Mock Bar 2", currentOccupancy: 50, currentLineWait: 10, isActive: true)
        ]
        return ContentView()
            .environmentObject(mockViewModel) // Pass mock data for preview
    }
}
