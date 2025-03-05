import SwiftUI
import CoreLocation

struct LocationPermissionPopup: View {
    var onRequestPermission: () -> Void
    var isDenied: Bool
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with icon and title
            VStack(spacing: 16) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.4, blue: 0.9), Color(red: 0.2, green: 0.5, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 28)
                    .opacity(isAnimated ? 1 : 0)
                    .offset(y: isAnimated ? 0 : -10)
                
                Text(isDenied ? "Location Access Denied" : "Location Access Required")
                    .font(.system(size: 22, weight: .semibold))
                    .opacity(isAnimated ? 1 : 0)
                    .foregroundColor(Color(UIColor.darkGray))
            }
            
            // Subtle divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.gray.opacity(0.2), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.vertical, 16)
                .padding(.horizontal, 40)
            
            // Description section
            Text(isDenied ?
                "CrowdSense needs location permissions to function properly. Please enable location access in Settings." :
                "CrowdSense needs 'Always' location permission for the best experience. Without this permission, certain features won't work correctly.")
                .font(.system(size: 17, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(UIColor.darkGray))
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 10)
            
            // Bottom section with button
            VStack {
                Button(action: {
                    onRequestPermission()
                    
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text(isDenied ? "Open Settings" : "Enable Location")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(SophisticatedButtonStyle())
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 28)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 10)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Pure white base
                Color.white
                
                // Very subtle blue gradient overlay
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(red: 0.9, green: 0.95, blue: 1.0), lineWidth: 1)
            }
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimated = true
            }
        }
    }
}

struct SophisticatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(
                    colors: [Color(red: 0.0, green: 0.4, blue: 0.9), Color(red: 0.2, green: 0.5, blue: 1.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(configuration.isPressed ? 0.9 : 1.0)
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
