//
//  EditPasswordView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import SwiftUI

struct EditPasswordView: View {
    // Environment vars
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presMode
    
    // Binding vars
    @Binding var showProfileView: Bool
    
    let user: User
    
    // State vars
    @State var password = ""
    @State var confirmPassword = ""
    @State var currentPassword = ""
    @State var errorMessage = ""
    
    @State var showError = false
    @State var showAlert = false
    
    // ObservedObject vars
    @ObservedObject var profileViewModel = ProfileViewModel()
    
    // Standard vars
    var isEmpty: Bool {
        currentPassword.trimmingCharacters(in: .whitespaces).isEmpty || confirmPassword.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty || confirmPassword != password
    }
    
    init(user: User, showProfileView: Binding<Bool>) {
        self.user = user
        self._showProfileView = showProfileView
    }
    
    var body: some View {
        VStack {
            // MARK: Navbar
            HStack(alignment: .center, spacing: 10) {
                // MARK: User info
                Text("Change Password")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                SheetCloseButton(isPresented: $showProfileView)
            }
            .padding()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    CustomPasswordField(text: $currentPassword, placeholder: "Current Password")
                    if !currentPassword.isEmpty && currentPassword.count >= 6 && currentPassword != user.password {
                        Text("Incorrect password.")
                            .foregroundColor(.red)
                    }
                    CustomPasswordField(text: $password, placeholder: "New Password")
                    CustomPasswordField(text: $confirmPassword, placeholder: "Confirm New Password")
                    if password != confirmPassword {
                        Text("Passwords don't match.")
                            .foregroundColor(Color.red)
                    }
                }
                .autocorrectionDisabled()
#if os(iOS)
                .autocapitalization(.none)
#endif
                .padding(.horizontal)
            }
            Button(action: {
                if password.count < 6 {
                    showError.toggle()
                } else {
                    profileViewModel.changePassword(user, newPassword: password, currentPassword: currentPassword) { success in
                        if success {
                            showProfileView = false
                        } else {
                            showError.toggle()
                        }
                    } completionString: { string in
                        errorMessage = string
                    }
                }
            }, label: {
                HStack {
                    Spacer()
                    Text("Change Password")
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
            })
            .opacity(isEmpty ? 0.5 : 1.0)
            .disabled(isEmpty)
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text("Your password must be at least 6 characters long."), dismissButton: .cancel(Text("Close")))
        }
        .onAppear {
            viewModel.fetchUser()
        }
    }
}
