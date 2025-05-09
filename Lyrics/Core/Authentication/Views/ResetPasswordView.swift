//
//  ResetPasswordView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/16/23.
//

import SwiftUI

struct ResetPasswordView: View {
    @State var showError = false
    @State var showSuccess = false
    
    @State var errorMessage = ""
    
    @Binding var text: String
    
    @FocusState var isFocused: Bool
    
    @ObservedObject var viewModel = AuthViewModel.shared
    
    @Environment(\.presentationMode) var presMode
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enter your email.")
                        .font(.title.weight(.bold))
                    Text("Enter the email associated with your account.")
                }
                Spacer()
                Button(action: {presMode.wrappedValue.dismiss()}) {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .background(Material.regular)
                        .clipShape(Circle())
                }
            }
            .padding()
            Divider()
            Spacer()
            CustomTextField(text: $text, placeholder: "Email", image: "envelope")
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .focused($isFocused)
                .padding()
                .onAppear {
                    isFocused = true
                }
            Spacer()
            Divider()
            LiveLyricsButton("Continue") {
                viewModel.resetPassword(email: text) { success, string  in
                    if success {
                        showSuccess.toggle()
                    } else {
                        errorMessage = string
                        showError.toggle()
                    }
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(text.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert(isPresented: $showSuccess) {
            Alert(title: Text("Success!"), message: Text("Check your email for further instructions."), dismissButton: .cancel(Text("OK"), action: {presMode.wrappedValue.dismiss()}))
        }
    }
}

#Preview {
    ResetPasswordView(text: .constant(""))
}
