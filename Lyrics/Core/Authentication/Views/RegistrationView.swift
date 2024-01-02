//
//  RegistrationView.swift
//  Touchbase
//
//  Created by Liam Willey on 2/24/23.
//

import SwiftUI
#if os(iOS)
import BottomSheet
#endif

struct RegistrationView: View {
    // State vars
    @State var email = ""
    @State var password = ""
    @State var confirmPassword = ""
    @State var fullname = ""
    @State var username = ""
    @State var errorMessage = ""
    
    @State var showWebView = false
    @State var showError = false
    
    // Other vars
    var isEmpty: Bool {
        email.trimmingCharacters(in: .whitespaces).isEmpty || username.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty || fullname.trimmingCharacters(in: .whitespaces).isEmpty || confirmPassword.trimmingCharacters(in: .whitespaces).isEmpty || confirmPassword != password
    }
    var attributedString: AttributedString = try! AttributedString(markdown: "[Privacy Policy](https://charger-tech-lyrics.web.app/privacypolicy.html)")
    
    // Environment vars
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presMode
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: Navbar
                HStack(alignment: .center, spacing: 10) {
                    Text("Sign Up")
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                    Spacer()
                    Button(action: {presMode.wrappedValue.dismiss()}) {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .padding(12)
                            .font(.body.weight(.semibold))
                            .foregroundColor(Color("Color"))
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                }
                .padding([.leading, .top, .trailing], 4)
                // MARK: Text Fields
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
                }
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
                    Button(action: {viewModel.register(withEmail: email, password: password, username: username, fullname: fullname) { success in
                        if !success {
                            showError.toggle()
                        }
                    } completionString: { string in
                        self.errorMessage = string
                    }}, label: {
                        HStack {
                            Spacer()
                            Text(NSLocalizedString("continue", comment: "Continue"))
                            Spacer()
                        }
                        .modifier(NavButtonViewModifier())
                    })
                    .disabled(isEmpty)
                    .opacity(isEmpty ? 0.5 : 1.0)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showWebView) {
            WebView()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
            .environmentObject(AuthViewModel())
    }
}
