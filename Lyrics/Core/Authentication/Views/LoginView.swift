//
//  LoginView.swift
//  Touchbase
//
//  Created by Liam Willey on 2/24/23.
//

import SwiftUI

struct LoginView: View {
    // State vars
    @State var email = ""
    @State var password = ""
    @State var errorMessage = ""
    
    @State var showRegister = false
    @State var showResetPassword = false
    @State var showError = false
    
    // Focus state vars
    @FocusState var isHighlighted1: Bool
    @FocusState var isHighlighted2: Bool
    
    // Standard vars
    var isEmpty: Bool {
        email.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty
    }
    var isHighlighted: Bool {
        isHighlighted1 || isHighlighted2
    }
    
    //Environment vars
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // MARK: Header View
            HStack(spacing: 8) {
                Text("Login")
                    .font(.system(size: 26).weight(.bold))
                Spacer()
            }
            Spacer()
            VStack(alignment: .leading, spacing: 15) {
                CustomTextField(text: $email, placeholder: "Email")
#if os(iOS)
                    .autocapitalization(.none)
#endif
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
            VStack(spacing: 10) {
                Button(action: {
                    viewModel.login(withEmail: email, password: password) { success in
                        if !success {
                            showError.toggle()
                        }
                    } completionString: { string in
                        self.errorMessage = string
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Text("Sign In")
                        Spacer()
                    }
                    .modifier(NavButtonViewModifier())
                })
                .opacity(isEmpty ? 0.5 : 1.0)
                .disabled(isEmpty)
                Button(action: {showRegister.toggle()}, label: {
                    Text("No account? ") + Text("Sign Up").bold()
                })
            }
        }
        .alert(isPresented: $showError, content: {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        })
        .padding()
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRegister) {
            RegistrationView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView(text: $email)
                .environmentObject(viewModel)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
