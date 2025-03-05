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
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 15/255, green: 15/255, blue: 40/255),
                    Color(red: 10/255, green: 10/255, blue: 30/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                // Pull-to-refresh control
                RefreshControl(coordinateSpace: .named("refresh")) {
                    await refreshData()
                }
                
                LazyVStack(spacing: 24) {
                    // Empty state
                    if viewModel.bars.isEmpty {
                        VStack(spacing: 24) {
                            Image(systemName: "wineglass")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 60)
                            
                            Text("No Bars Available")
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Pull down to refresh or check back later")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    
                    // Loop through the bars and display tiles
                    ForEach(viewModel.bars, id: \.id) { bar in
                        if bar.id != expandedBarId {
                            createBarTile(for: bar)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .zIndex(1)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .coordinateSpace(name: "refresh")
            
            // Semi-transparent overlay when a bar is expanded
            if expandedBarId != -1 {
                Color(red: 10/255, green: 10/255, blue: 30/255)
                    .opacity(0.7)
                    .ignoresSafeArea()
                    .contentShape(Rectangle()) // Ensure entire area is tappable
                    .onTapGesture {
                        // Collapse all expanded tiles with animation
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            expandedBarId = -1
                        }
                    }
                    .zIndex(0.5) // Lower zIndex to be below the expanded BarTile
            }
            
            // Expanded bar display
            if let expandedBar = viewModel.bars.first(where: { $0.id == expandedBarId }) {
                BarTile(
                    bar: expandedBar,
                    isExpanded: true,
                    onExpand: { id in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            expandedBarId = id
                        }
                    },
                    viewModel: viewModel,
                    namespace: animationNamespace,
                    expandedBarId: $expandedBarId
                )
                .matchedGeometryEffect(id: "bar_\(expandedBar.id)", in: animationNamespace)
                .zIndex(1) // Ensure expanded BarTile is above the overlay
                .padding(.top, -275)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            // Fetch data when the view appears
            viewModel.fetchBars()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("CrowdSense")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    // Create a bar tile with modern styling
    private func createBarTile(for bar: Bar) -> some View {
        BarTile(
            bar: bar,
            isExpanded: expandedBarId == bar.id, // Determine if this tile is expanded
            onExpand: { id in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    expandedBarId = id // Expand or collapse based on the passed ID
                }
            },
            viewModel: viewModel,
            namespace: animationNamespace,
            expandedBarId: $expandedBarId
        )
        .matchedGeometryEffect(id: "bar_\(bar.id)", in: animationNamespace)
        // Add a subtle hover effect
        .scaleEffect(1.0)
        .shadow(color: Color.blue.opacity(0.15), radius: 5, x: 0, y: 3)
        // Enable tap on entire tile
        .contentShape(Rectangle())
        // Add subtle tap animation
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Async refresh function for pull-to-refresh
    private func refreshData() async {
        isRefreshing = true
        // Simulate network delay if needed
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        viewModel.fetchBars()
        isRefreshing = false
    }
}

// Custom button style for scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Pull-to-refresh control
struct RefreshControl: View {
    var coordinateSpace: CoordinateSpace
    var onRefresh: () async -> Void
    
    @State private var isRefreshing = false
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: coordinateSpace).minY > 20 && !isRefreshing {
                Spacer()
                    .onAppear {
                        isRefreshing = true
                        Task {
                            await onRefresh()
                            isRefreshing = false
                        }
                    }
            }
            
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .tint(.white)
                } else if offset > 0 {
                    Text("Pull to refresh")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .offset(y: -30)
            .onAppear {
                offset = geo.frame(in: coordinateSpace).minY
            }
            .onChange(of: geo.frame(in: coordinateSpace).minY) { oldValue, newValue in
                offset = newValue
            }
        }
        .frame(height: 0)
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
