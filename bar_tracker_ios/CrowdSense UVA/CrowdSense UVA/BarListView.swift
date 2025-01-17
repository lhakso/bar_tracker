//
//  BarListView.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/16/25.
//

import SwiftUI

struct BarListView: View {
    @StateObject private var viewModel = BarListViewModel() // ViewModel to fetch bar data

    var body: some View {
        ZStack {
            // Background color
            Color(red: 10/255, green: 10/255, blue: 60/255)
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 20) {
                    // Loop through the bars and display tiles
                    ForEach(viewModel.bars, id: \.id) { bar in
                        BarTile(bar: bar, viewModel: viewModel)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // Fetch data when the view appears
            print("onAppear triggered in BarListView")
            viewModel.fetchBars()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("CrowdSense")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

struct BarListView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock ViewModel for previews
        let mockViewModel = BarListViewModel()
        mockViewModel.bars = [
            Bar(id: 1, name: "Mock Bar 1", currentOccupancy: 75, currentLineWait: 5, isActive: true),
            Bar(id: 2, name: "Mock Bar 2", currentOccupancy: 50, currentLineWait: 10, isActive: true)
        ]

        return BarListView()
            .environmentObject(mockViewModel)
    }
}
