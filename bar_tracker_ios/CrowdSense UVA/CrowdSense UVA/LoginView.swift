import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var showRegistration: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .bold()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal)

            // Pass the password binding to ShowPasswordField
            ShowPasswordField(password: $password)

            if isLoading {
                ProgressView()
            } else {
                Button(action: handleLogin) {
                    Text("Login")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()
            Button("Create Account") {
                showRegistration = true
            }
            .padding()
            .sheet(isPresented: $showRegistration) {
                RegistrationView()
            }
        }
        .padding()
    }

    private func handleLogin() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter username and password."
            return
        }

        errorMessage = nil
        isLoading = true

        authVM.login(username: username, password: password) { success in
            isLoading = false
            if !success {
                errorMessage = "Login failed. Check your credentials."
            }
        }
    }
}

// Updated ShowPasswordField that uses a Binding
struct ShowPasswordField: View {
    @Binding var password: String
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        HStack {
            if isPasswordVisible {
                TextField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            Button(action: {
                isPasswordVisible.toggle()
            }) {
                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
}
