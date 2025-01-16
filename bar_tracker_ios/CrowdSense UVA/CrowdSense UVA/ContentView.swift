//
//  ContentView.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/12/25.
//

import SwiftUI

struct ContentView: View {
    // List of bars to display
    let bars = [
        Bar(id: 1, name: "Trinity", occupancy: 5, lineWait: 2),
        Bar(id: 2, name: "Boylan", occupancy: 7, lineWait: 8),
        Bar(id: 3, name: "Coupes", occupancy: 9, lineWait: 6),
    ]
    init() {
        // Customize Navigation Bar appearance to prevent transparency
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 80/255, alpha: 1) // Slightly lighter navy
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white] // White title text
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    var body: some View {
        ZStack {
            // Background color (goes first to be at the back)
            Color(red: 10/255, green: 10/255, blue: 60/255)
                .ignoresSafeArea() // Ensure the background covers the entire screen
            
            NavigationView {
                ScrollView { // Use ScrollView to manage spacing and scrolling
                    LazyVStack(spacing: 20) { // Add vertical spacing between tiles
                        ForEach(bars) { bar in
                            BarTile(bar: bar)
                                .padding(.horizontal) // Add horizontal padding for tiles
                        }
                    }
                    .padding(.top) // Add top padding
                    .background(
                        Color(red: 20/255, green: 20/255, blue: 80/255) // Explicitly set the ScrollView background
                            .ignoresSafeArea()
                    )
                }
                //.navigationTitle("Bar Tracker") // Title of the screen
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Bar Tracker")
                            .font(.headline)
                            .foregroundColor(.white) // Make the title white
                    }
                }
                    .background(
                        Color(red: 20/255, green: 20/255, blue: 80/255) // Explicitly set the NavigationView background
                            .ignoresSafeArea()
                    )
                }
            }
        }
    }
    
