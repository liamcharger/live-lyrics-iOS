//
//  DeleteAccountView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/7/25.
//

import SwiftUI

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
