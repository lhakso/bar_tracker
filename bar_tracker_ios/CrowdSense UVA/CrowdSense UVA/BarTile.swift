import SwiftUI

struct BarTile: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager
    let bar: Bar
    let isExpanded: Bool
    let onExpand: (Int) -> Void // Callback to notify parent about expansion
    @ObservedObject var viewModel: BarListViewModel
    var namespace: Namespace.ID
    @State private var occupancy: Double = 5
    @State private var lineWait: Double = 0
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Main bar info
            Text(bar.name)
                .font(.title2)
                .foregroundColor(.white)
                .matchedGeometryEffect(id: "title_\(bar.id)", in: namespace)

            // If not expanded, show the "Submit Report" button
            if !isExpanded {
                HStack {
                    Text("Occupancy: \(bar.currentOccupancy ?? 0)")
                    Spacer()
                    Text("Line Wait: \(bar.currentLineWait ?? 0) mins")
                }
                .foregroundColor(.white.opacity(0.85))

                Button(action: {
                    withAnimation {
                        onExpand(bar.id)
                    }
                }) {
                    Text("Submit Report")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            // If expanded, show the sliders + "Submit" button
            else {
                VStack {
                    Text("Occupancy")
                        .foregroundColor(.white)
                        .matchedGeometryEffect(id: "occupancy_title_\(bar.id)", in: namespace)
                    HStack {
                        Text("Dead")
                            .foregroundColor(.white)
                            .padding(.horizontal, -20)

                        LabeledSlider(
                            value: $occupancy,
                            range: 1...10,
                            step: 1,
                            unitString: ""
                        )

                        Text("Max")
                            .foregroundColor(.white)
                            .padding(.horizontal, -20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .matchedGeometryEffect(id: "occupancy_slider_\(bar.id)", in: namespace)

                    
                    Text("Line Wait")
                        .foregroundColor(.white)
                        .matchedGeometryEffect(id: "linewait_title_\(bar.id)", in: namespace)
                    HStack {
                        Text("No wait")
                            .foregroundColor(.white)
                            .padding(.horizontal, -20)

                        LabeledSlider(
                            value: $lineWait,
                            range: 0...60,
                            step: 5,
                            unitString: "mins"
                        )

                        Text("60+ mins")
                            .foregroundColor(.white)
                            .padding(.horizontal, -20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .matchedGeometryEffect(id: "linewait_slider_\(bar.id)", in: namespace)
                    Button(action: {
                        // Print debugging info
                        print("Bar: \(bar.name), Occupancy: \(occupancy), Line Wait: \(lineWait), user: \(authVM.user)")
                        // Submit to the backend
                        if locationManager.userIsNearBar {
                            
                            
                            viewModel.submitOccupancy(
                                barId: String(bar.id),
                                occupancy: Int(occupancy),
                                lineWait: Int(round(lineWait / 6.0)), // Example: mapping 0-60 -> 0-10
                                user: authVM.user,                     // use environment object
                                locationManager: locationManager,
                                completion: { success in
                                    // do something
                                }
                            )
                        }

                        // Collapse the panel with animation
                        withAnimation {
                            onExpand(-1)

                        }
                    }) {
                        Text("Submit")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding()
                    .matchedGeometryEffect(id: "submit_button_\(bar.id)", in: namespace)
                }
                .transition(.scale)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 170)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 40/255, green: 50/255, blue: 100/255),
                    Color(red: 60/255, green: 70/255, blue: 120/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
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
    
    /// Show “60+” if at max, otherwise just integer + optional unit (e.g. "mins").
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
        
        // 4. Arrow “right” edge
        path.addLine(to: CGPoint(x: midX + arrowSize, y: h - arrowSize))
        
        // Arrow tip at bottom center
        path.addLine(to: CGPoint(x: midX, y: h))
        
        // Arrow “left” edge
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
