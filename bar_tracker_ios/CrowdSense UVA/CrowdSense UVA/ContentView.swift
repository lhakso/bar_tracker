//
//  ContentView.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/12/25.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    // ViewModel to fetch and manage data
    @EnvironmentObject var viewModel: BarListViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var expandedBarId: Int? = -1
    @State private var showProfile = false
    @StateObject private var locationManager = LocationManager()
    private let manager = CLLocationManager()
    
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

            NavigationStack {
                BarListView(expandedBarId: $expandedBarId) // Using BarListView directly
                    .navigationBarTitleDisplayMode(.inline) // Ensures consistent title placement
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("CrowdSense")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(destination: ProfileView()) {
                                Image(systemName: "line.horizontal.3")
                                    .imageScale(.large)
                                    .foregroundColor(.white)
                            }
                        }
                    }
            }
            .onAppear {
                manager.requestWhenInUseAuthorization()
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = BarListViewModel()
        mockViewModel.bars = [
            Bar(id: 1, name: "Mock Bar 1", currentOccupancy: 75, currentLineWait: 5, isActive: true, latitude: -64.1333, longitude: 27.7167),
            Bar(id: 2, name: "Mock Bar 2", currentOccupancy: 50, currentLineWait: 10, isActive: true, latitude: -45.8167, longitude: 14.7833)
        ]

        return ContentView()
            .environmentObject(mockViewModel)
            .environmentObject(AuthViewModel())
    }
}
