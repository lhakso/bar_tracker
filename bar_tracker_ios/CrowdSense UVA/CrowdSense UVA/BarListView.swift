//
//  BarListView.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/16/25.
//

import SwiftUI

struct BarListView: View {
    @EnvironmentObject var viewModel: BarListViewModel // ViewModel to fetch bar data
    @Binding var expandedBarId: Int?
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            // Background color
            Color(red: 10/255, green: 10/255, blue: 60/255)
                .ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Loop through the bars and display tiles

                    ForEach(viewModel.bars, id: \.id) { bar in
                        if bar.id != expandedBarId {
                            createBarTile(for: bar)
                        }
                    }
                }
                .zIndex(1)
                
                .padding()
                
            }
            if expandedBarId != -1 {
                Color(red: 10/255, green: 10/255, blue: 60/255)
                //Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .contentShape(Rectangle()) // Ensure entire area is tappable
                    .onTapGesture {
                        // Collapse all expanded tiles
                        withAnimation {
                            expandedBarId = -1
                        }
                    }
                    .zIndex(0.5) // Lower zIndex to be below the expanded BarTile
            }
            if let expandedBar = viewModel.bars.first(where: { $0.id == expandedBarId }) {
                BarTile(
                    bar: expandedBar,
                    isExpanded: true,
                    onExpand: { id in
                        withAnimation {
                            expandedBarId = id
                        }
                    },
                    viewModel: viewModel,
                    namespace: animationNamespace
                )
                .matchedGeometryEffect(id: "bar_\(expandedBar.id)", in: animationNamespace)
                .zIndex(1) // Ensure expanded BarTile is above the overlay
                .padding(.top, -275)
            }
        }

        .onAppear {
            // Fetch data when the view appears
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
    private func createBarTile(for bar: Bar) -> some View {
        
        BarTile(
            bar: bar,
            isExpanded: expandedBarId == bar.id, // Determine if this tile is expanded
            onExpand: { id in
                withAnimation {
                    expandedBarId = id // Expand or collapse based on the passed ID
                }
            
            },
            viewModel: viewModel,
            namespace: animationNamespace
        )
        .matchedGeometryEffect(id: "bar_\(bar.id)", in: animationNamespace)
    }
}

struct BarListView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock ViewModel for previews
        let mockViewModel = BarListViewModel()
        mockViewModel.bars = [
            Bar(id: 1, name: "Mock Bar 1", currentOccupancy: 75, currentLineWait: 5, isActive: true, latitude: -80.55, longitude: 74.55),
            Bar(id: 2, name: "Mock Bar 2", currentOccupancy: 50, currentLineWait: 10, isActive: true, latitude: -60.55, longitude: 64.55)
        ]

        return BarListView(expandedBarId: .constant(-1))
            .environmentObject(mockViewModel)
    }
    
}


