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
                            Text("Reset Password")
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
