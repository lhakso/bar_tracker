//
//  ProfileEditView.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 1/24/25.
//
/*
import SwiftUI

struct ProfileEditView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var isEditing: Bool
    @State private var newEmail: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("New Email", text: $newEmail)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    authVM.updateEmail(newEmail: newEmail) { success in
                        if success {
                            isEditing = false
                        }
                    }
                }) {
                    Text("Save")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isEditing = false
                }
            )
            .navigationBarTitleDisplayMode(.inline)                    // Use inline title (looks neater)
            .toolbarBackground(Color(red: 10/255, green: 10/255, blue: 60/255), for: .navigationBar)        // Dark/blue background
            .toolbarBackground(.visible, for: .navigationBar)          // Ensure the background is visible
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
*/
