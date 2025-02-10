//
//  ProfileView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/16/23.
//

import SwiftUI
import BottomSheet


struct ProfileView: View {
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    @Environment(\.presentationMode) var presMode
    
    @Binding var isPresented: Bool
    
    let user: User
    
    @State var fullname = ""
    @State var username = ""
    @State var email = ""
    @State var errorMessage = ""
    
    @State var showError = false
    @State var showChangePasswordView = false
    @State var showDeleteSheet = false
    
    var isEmpty: Bool {
        fullname.trimmingCharacters(in: .whitespaces).isEmpty || username.trimmingCharacters(in: .whitespaces).isEmpty || email.trimmingCharacters(in: .whitespaces).isEmpty || user.fullname != fullname || user.username != username || user.email != email
    }
    
    init(user: User, isPresented: Binding<Bool>) {
        self.user = user
        
        self._email = State(initialValue: user.email)
        self._fullname = State(initialValue: user.fullname)
        self._username = State(initialValue: user.username)
        self._isPresented = isPresented
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Edit Profile")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                CloseButton {
                    isPresented = false
                }
            }
            .padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading) {
                    CustomTextField(text: $email, placeholder: "Email", image: "envelope")
                    CustomTextField(text: $fullname, placeholder: "Fullname", image: "person")
                    CustomTextField(text: $username, placeholder: "Username", image: "person")
                    Button {
                        showChangePasswordView = true
                    } label: {
                        HStack(spacing: 7) {
                            Text("Change Password")
                            Spacer()
                            FAText(iconName: "arrow-right", size: 20)
                        }
                        .padding()
                        .background(Material.regular)
                        .clipShape(Capsule())
                        .foregroundColor(.primary)
                    }
                    .sheet(isPresented: $showChangePasswordView) {
                        ResetPasswordView(text: $email)
                    }
                    .padding(.top)
                    Button(role: .destructive) {
                        showDeleteSheet = true
                    } label: {
                        HStack(spacing: 7) {
                            Text("Delete Account")
                            Spacer()
                            FAText(iconName: "trash-can", size: 20)
                        }
                        .padding()
                        .background(Material.regular)
                        .clipShape(Capsule())
                        .foregroundColor(.red)
                    }
                    .sheet(isPresented: $showDeleteSheet) {
                        DeleteAccountView(showError: $showError, errorMessage: $errorMessage)
                    }
                }
                .padding()
            }
            Divider()
            LiveLyricsButton("Save") {
                authViewModel.updateUser(email: email, username: username, fullname: fullname) { success in
                    if success {
                        isPresented = false
                    } else {
                        showError.toggle()
                    }
                } completionString: { string in
                    errorMessage = string
                }
            }
            .opacity(!isEmpty ? 0.5 : 1.0)
            .disabled(!isEmpty)
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel()) // FIXME: button is locked after error
        }
    }
}

struct DeleteAccountView: View {
    @Environment(\.presentationMode) var presMode
    
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    @State var showDeleteConfirmation = false
    
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    func deleteAccount() {
        authViewModel.deleteUser { success, errorMessage in
            if success {
                self.presMode.wrappedValue.dismiss()
            } else {
                self.showError = true
                self.errorMessage = errorMessage
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                CloseButton {
                    presMode.wrappedValue.dismiss()
                }
            }
            Spacer()
            Image(systemName: "trash")
                .font(.system(size: 34).weight(.semibold))
                .foregroundColor(.red)
            Text(NSLocalizedString("delete_account_confirmation_short", comment: ""))
                .font(.largeTitle.weight(.bold))
            Text("WARNING: This action is permanant and cannot be undone!")
                .font(.title3.weight(.bold))
                .foregroundColor(.gray)
            Spacer()
            Button {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 7) {
                            Text("Delete Account")
                            Spacer()
                            Image(systemName: "trash")
                        }
                        .font(.body.weight(.semibold))
                    }
                }
                .padding()
                .foregroundColor(.white)
                .background {
                    Rectangle()
                        .fill(.clear)
                        .background(Color.red)
                        .mask { Capsule() }
                }
            }
            .padding(.top)
        }
        .multilineTextAlignment(.center)
        .padding()
        .confirmationDialog("Delete User Account", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                self.deleteAccount()
            }
            Button("Cancel", role: .cancel) {
                self.showDeleteConfirmation = false
                self.presMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this user account? WARNING: THIS ACTION IS PERMANENT AND CANNOT BE UNDONE!")
        }
    }
}
