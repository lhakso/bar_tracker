import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isEditing = false

    var body: some View {
        NavigationView {
            ZStack {
                // Subtle gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 24/255, green: 24/255, blue: 70/255),
                        Color(red: 10/255, green: 10/255, blue: 60/255)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Avatar placeholder
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .padding(.top, 40)

                    // User info card
                    VStack(spacing: 8) {
                        Text(authVM.user)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)

                        Text(authVM.email)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Less conspicuous "Edit Profile" button
                    Button(action: {
                        isEditing = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "pencil")
                            Text("Edit Profile")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    }
                    // Makes it behave more like a text/link and avoids a large, colored background:
                    .buttonStyle(.borderless)
                    // Slight padding so it doesn’t feel cramped:
                    .padding(.vertical, 8)

                    // Logout button
                    Button(action: {
                        authVM.logout() // Perform logout action
                    }) {
                        HStack {
                            Image(systemName: "arrowshape.turn.up.left")
                            Text("Logout")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.bottom, 40)
                .navigationBarTitle("Profile", displayMode: .inline)
                .sheet(isPresented: $isEditing) {
                    ProfileEditView(isEditing: $isEditing)
                }
            }
        }
        .onAppear {
            fetchUserEmail()
        }
    }

    private func fetchUserEmail() {
        AuthService.shared.fetchEmail { email in
            DispatchQueue.main.async {
                if let email = email {
                    authVM.email = email
                } else {
                    print("Failed to fetch email")
                }
            }
        }
    }
}
