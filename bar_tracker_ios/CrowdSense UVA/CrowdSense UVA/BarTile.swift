import SwiftUI

struct BarTile: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager
    let bar: Bar
    let isExpanded: Bool
    let onExpand: (Int) -> Void // callback to notify parent about expansion
    @ObservedObject var viewModel: BarListViewModel
    var namespace: Namespace.ID
    @State private var occupancy: Double = 5
    @State private var lineWait: Double = 0
    @Binding var expandedBarId: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // main bar info
            Text(bar.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(isExpanded ? 1.18 : 1.0, anchor: .leading)
                .matchedGeometryEffect(id: "title_\(bar.id)", in: namespace)

            // If not expanded, show basic info and "Submit Report" button
            if !isExpanded {
                // Status indicators with colored dots
                HStack(spacing: 12) {
                    // Occupancy indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(occupancyColor(for: bar.currentOccupancy ?? 0))
                            .frame(width: 8, height: 8)
                        
                        Text("Occupancy: \(bar.currentOccupancy.map { String($0) } ?? "No Data")")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Spacer()
                    
                    // Line wait indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(lineWaitColor(for: bar.currentLineWait ?? 0))
                            .frame(width: 8, height: 8)
                            
                        Text("Line Wait: \(bar.currentLineWait.map { "\($0) mins" } ?? "No Data")")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .foregroundColor(.white.opacity(0.9))

                Button(action: {
                    withAnimation(.linear(duration: 0.25)) {
                        onExpand(bar.id)
                    }
                }) {
                    Text("Submit Report")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.8),
                                    Color.blue
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 4)
            }
            // If expanded, show the sliders + "Submit" button
            else {
                VStack(spacing: 20) {
                    // Occupancy section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Occupancy")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack {
                            Text("Dead")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, -16)

                            LabeledSlider(
                                value: $occupancy,
                                range: 1...10,
                                step: 1,
                                unitString: ""
                            )
                            .matchedGeometryEffect(id: "occupancy_slider_\(bar.id)", in: namespace)

                            Text("Max")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, -16)
                        }
                        .padding(.horizontal)
                        .padding(.top, 17)
                    }
                    
                    // Line Wait section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Line Wait")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack {
                            Text("No wait")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, -16)

                            LabeledSlider(
                                value: $lineWait,
                                range: 0...60,
                                step: 5,
                                unitString: "mins"
                            )
                            .matchedGeometryEffect(id: "linewait_slider_\(bar.id)", in: namespace)

                            Text("60+ mins")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, -16)
                        }
                        .padding(.horizontal)
                        .padding(.top, 17)
                    }
                    
                    // submit button
                    Button(action: {
                        // Print debugging info
                        print("Bar: \(bar.name), Occupancy: \(occupancy), Line Wait: \(lineWait)")
                        
                        // Ensure we have an expanded bar
                        guard let expandedBar = viewModel.bars.first(where: { $0.id == expandedBarId }) else {
                            print("No expanded bar found")
                            return
                        }
                        
                        withAnimation(.linear(duration: 0.25)) {
                            onExpand(-1)
                        }
                        
                        // Check proximity asynchronously
                        if let barLocation = BarLocationDataStore.shared.load()?.first(where: { $0.id == expandedBar.id }) {
                            LocationManager.shared.checkUserProximityForSubmission(barLocation: barLocation) { isNear in
                                print("User near bar?: \(isNear)")
                                guard isNear else {
                                    print("User is not near the bar – submission aborted.")
                                    // Collapse the panel with animation even if submission is aborted
                                    withAnimation(.linear(duration: 0.25)) {
                                        onExpand(-1)
                                    }
                                    return
                                }
                                
                                print("User is near bar – proceeding with submission.")
                                viewModel.submitOccupancy(
                                    barId: expandedBar.id,
                                    occupancy: Int(occupancy),
                                    lineWait: Int(round(lineWait / 6.0)), // Mapping 0-60 -> 0-10
                                    completion: { success in
                                        // Handle the submission result if needed
                                        print("Occupancy submission success: \(success)")
                                    }
                                )
                            }
                        } else {
                            print("No matching BarLocation found for bar id: \(expandedBar.id)")
                            withAnimation(.linear(duration: 0.25)) {
                                onExpand(-1)
                            }
                        }
                    }) {
                        Text("Submit")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.green.opacity(0.8),
                                        Color.green
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 8)
                    .matchedGeometryEffect(id: "submit_button_\(bar.id)", in: namespace)
                }
                .transition(.opacity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 170)
        .background(
            ZStack {
                // Main gradient background
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 50/255, green: 60/255, blue: 110/255),
                                Color(red: 40/255, green: 50/255, blue: 90/255)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle inner glow at the top
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(lineWidth: 2)
                    )
            }
        )
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        .shadow(color: Color.blue.opacity(0.15), radius: 5, x: 0, y: 3)
        .animation(.linear(duration: 0.25), value: isExpanded)
    }
    
    // Helper for occupancy color
    private func occupancyColor(for value: Int) -> Color {
        switch value {
        case 0...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        default: return .red
        }
    }
    
    // Helper for line wait color
    private func lineWaitColor(for minutes: Int) -> Color {
        switch minutes {
        case 0...5: return .green
        case 6...15: return .yellow
        case 16...30: return .orange
        default: return .red
        }
    }
}

struct LabeledSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unitString: String
    
    private let knobRadius: CGFloat = 15

    var body: some View {
        ZStack {
            // 1) The main Slider (no padding, so geometry is exact).
            Slider(value: $value, in: range, step: step)
                .accentColor(.blue)

            // 2) GeometryReader to figure out how wide the slider is.
            GeometryReader { geo in
                let fraction = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                let trackWidth = geo.size.width - 2 * knobRadius
                let xPos = knobRadius + fraction * trackWidth
                
                // 3) The label with callout bubble
                Text(labelText)
                    .font(.caption)
                    .foregroundColor(.black)
                    // Extra vertical padding so the text sits above the arrow
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 8)
                    .background(
                        CalloutBubble()
                            .fill(Color.white)
                    )
                    // Position so the arrow points down toward the slider thumb
                    // We shift it *up* by ~29 pts from slider center; adjust as you like.
                    .position(
                        x: xPos,
                        y: geo.size.height / 2 - 30
                    )
            }
        }
        .frame(height: 40)
        .padding(.horizontal)
    }
    
    /// Show "60+" if at max, otherwise just integer + optional unit (e.g. "mins").
    private var labelText: String {
        let intValue = Int(value)
        if range.upperBound == 60, intValue == 60 {
            return "60+ \(unitString)"
        }
        return "\(intValue) \(unitString)"
    }
}

struct CalloutBubble: Shape {
    /// How large (tall) the bottom arrow is.
    let arrowSize: CGFloat = 8
    /// How large the corner radius of the rectangle part is.
    let cornerRadius: CGFloat = 8
    
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let midX = w / 2
        
        var path = Path()
        
        // 1. Start at top-left corner, using a rounded corner.
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        
        // Top-left corner arc
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        
        // 2. Top edge to top-right corner
        path.addLine(to: CGPoint(x: w - cornerRadius, y: 0))
        
        // Top-right corner arc
        path.addQuadCurve(
            to: CGPoint(x: w, y: cornerRadius),
            control: CGPoint(x: w, y: 0)
        )
        
        // 3. Right edge down toward the arrow
        path.addLine(to: CGPoint(x: w, y: h - arrowSize - cornerRadius))
        
        // Bottom-right corner arc (above arrow)
        path.addQuadCurve(
            to: CGPoint(x: w - cornerRadius, y: h - arrowSize),
            control: CGPoint(x: w, y: h - arrowSize)
        )
        
        // 4. Arrow "right" edge
        path.addLine(to: CGPoint(x: midX + arrowSize, y: h - arrowSize))
        
        // Arrow tip at bottom center
        path.addLine(to: CGPoint(x: midX, y: h))
        
        // Arrow "left" edge
        path.addLine(to: CGPoint(x: midX - arrowSize, y: h - arrowSize))
        
        // 5. Bottom-left corner arc (above arrow)
        path.addLine(to: CGPoint(x: cornerRadius, y: h - arrowSize))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h - arrowSize - cornerRadius),
            control: CGPoint(x: 0, y: h - arrowSize)
        )
        
        // 6. Close up to the top-left
        path.closeSubpath()
        
        return path
    }
}

// Note: ScaleButtonStyle is already defined in BarListView.swift
