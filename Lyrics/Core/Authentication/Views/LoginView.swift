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
    
    @FocusState var isHighlighted1: Bool
    @FocusState var isHighlighted2: Bool
    
    var isEmpty: Bool {
        email.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presMode
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 12) {
                Button(action: {
                    action()
                }, label: {
                    Image(systemName: "chevron.left")
                        .padding()
                        .font(.body.weight(.semibold))
                        .background(Material.regular)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                })
                Text("Login")
                    .lineLimit(1)
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
            }
            Spacer()
            VStack(alignment: .leading) {
                CustomTextField(text: $email, placeholder: "Email")
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isHighlighted1)
                CustomPasswordField(text: $password, placeholder: "Password")
                    .autocorrectionDisabled()
                    .focused($isHighlighted2)
                Button(action: {showResetPassword.toggle()}, label: {
                    Text("Forgot Password?")
                })
            }
            Spacer()
            LiveLyricsButton("Sign In") {
                viewModel.login(withEmail: email, password: password) { success in
                    if !success {
                        showError.toggle()
                    }
                } completionString: { string in
                    self.errorMessage = string
                }
            }
            .opacity(isEmpty ? 0.5 : 1.0)
            .disabled(isEmpty)
        }
        .alert(isPresented: $showError, content: {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        })
        .padding()
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView(text: $email)
                .environmentObject(viewModel)
        }
    }
}

#Preview {
    LoginView(action: {})
}
