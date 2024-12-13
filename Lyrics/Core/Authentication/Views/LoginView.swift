//
//  LoginView.swift
//  Touchbase
//
//  Created by Liam Willey on 2/24/23.
//

import SwiftUI

struct LoginView: View {
    let action: () -> Void
    
    @State var email = ""
    @State var password = ""
    @State var errorMessage = ""
    
    @State var showResetPassword = false
    @State var showError = false
    @State var isButtonLoading = false
    
    @FocusState var isEmailFocused: Bool
    @FocusState var isPasswordFocused: Bool
    
    var isEmpty: Bool {
        email.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    @ObservedObject var viewModel = AuthViewModel.shared
    
    @Environment(\.presentationMode) var presMode
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 12) {
                Button {
                    action()
                } label: {
                    Image(systemName: "chevron.left")
                        .padding()
                        .font(.body.weight(.semibold))
                        .background(Material.regular)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                }
                Text("Login")
                    .lineLimit(1)
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
            }
            Spacer()
            VStack(alignment: .leading) {
                CustomTextField(text: $email, placeholder: "Email", image: "envelope")
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isEmailFocused)
                CustomPasswordField(text: $password, placeholder: "Password", image: "lock")
                    .autocorrectionDisabled()
                    .focused($isPasswordFocused)
                Button { showResetPassword.toggle() } label: {
                    Text("Forgot Password?")
                }
            }
            Spacer()
            LiveLyricsButton("Sign In", showProgressIndicator: $isButtonLoading) {
                isButtonLoading = true
                viewModel.login(withEmail: email, password: password) { success in
                    if !success {
                        showError.toggle()
                        isButtonLoading = false
                    }
                } completionString: { string in
                    self.errorMessage = string
                }
            }
            .opacity(isEmpty ? 0.5 : 1.0)
            .disabled(isEmpty)
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
        .padding()
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView(text: $email)
        }
    }
}

#Preview {
    LoginView(action: {})
}
