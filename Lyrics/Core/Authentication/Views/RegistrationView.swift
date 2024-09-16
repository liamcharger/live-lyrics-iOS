//
//  RegistrationView.swift
//  Touchbase
//
//  Created by Liam Willey on 2/24/23.
//

import SwiftUI

struct RegistrationView: View {
    let action: () -> Void
    
    @State var email = ""
    @State var password = ""
    @State var confirmPassword = ""
    @State var fullname = ""
    @State var username = ""
    @State var errorMessage = ""
    
    @State var showWebView = false
    @State var showError = false
    
    @State var isButtonLoading = false
    
    var isEmpty: Bool {
        email.trimmingCharacters(in: .whitespaces).isEmpty || username.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty || fullname.trimmingCharacters(in: .whitespaces).isEmpty || confirmPassword.trimmingCharacters(in: .whitespaces).isEmpty || confirmPassword != password
    }
    
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presMode
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
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
                    Text("Register")
                        .lineLimit(1)
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                    Spacer()
                }
                .padding()
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        CustomTextField(text: $email, placeholder: "Email")
                        CustomTextField(text: $username, placeholder: "Username")
                        CustomTextField(text: $fullname, placeholder: "Fullname")
#if os(iOS)
                            .autocapitalization(.words)
#endif
                        CustomPasswordField(text: $password, placeholder: "Password")
                        CustomPasswordField(text: $confirmPassword, placeholder: "Confirm Password")
                        if password != confirmPassword {
                            Text("Passwords don't match.")
                                .foregroundColor(Color.red)
                        }
                    }
                    .autocorrectionDisabled(true)
#if os(iOS)
                    .autocapitalization(.none)
#endif
                    .padding()
                }
                Divider()
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("By signing up, you're agree to our ")
                        + Text("Privacy Policy")
                            .foregroundColor(Color.blue)
                            .font(.footnote.weight(.semibold))
                        + Text(".")
                    }
                    .onTapGesture {
                        showWebView.toggle()
                    }
                    .foregroundColor(Color.gray)
                    .font(.footnote)
                    LiveLyricsButton("Continue", showProgressIndicator: $isButtonLoading) {
                        isButtonLoading = true
                        
                        viewModel.register(withEmail: email, password: password, username: username, fullname: fullname) { success in
                            if !success {
                                showError.toggle()
                                isButtonLoading = false
                            }
                        } completionString: { string in
                            self.errorMessage = string
                        }
                    }
                    .disabled(isEmpty)
                    .opacity(isEmpty ? 0.5 : 1.0)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showWebView) {
            PrivacyPolicyView()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }
}
