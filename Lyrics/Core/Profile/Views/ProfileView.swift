//
//  ProfileView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/16/23.
//

import SwiftUI
#if os(iOS)
import BottomSheet
#endif


struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presMode
    
    @Binding var showProfileView: Bool
    
    let user: User
    
    @State var fullname = ""
    @State var username = ""
    @State var email = ""
    @State var errorMessage = ""
    
    @State var showError = false
    @State var showAlert = false
    @State var showChangePasswordView = false
    @State var showDeleteSheet = false
    @State var showDeleteConfirmation = false
    @State var showManageSubscription = false
    
    var isEmpty: Bool {
        fullname.trimmingCharacters(in: .whitespaces).isEmpty || username.trimmingCharacters(in: .whitespaces).isEmpty || email.trimmingCharacters(in: .whitespaces).isEmpty || user.fullname != fullname || user.username != username || user.email != email
    }
    
    init(user: User, showProfileView: Binding<Bool>) {
        self.user = user
        self._email = State(initialValue: user.email)
        self._fullname = State(initialValue: user.fullname)
        self._username = State(initialValue: user.username)
        self._showProfileView = showProfileView
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Edit Profile")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                SheetCloseButton(isPresented: $showProfileView)
            }
            .padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading) {
                    CustomTextField(text: $email, placeholder: "Email")
                    CustomTextField(text: $fullname, placeholder: "Fullname")
                    CustomTextField(text: $username, placeholder: "Username")
                    Button(action: {
                        showChangePasswordView.toggle()
                    }, label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 7) {
                                    Text("Change Password")
                                    Spacer()
                                    FAText(iconName: "arrow-right", size: 20)
                                        .imageScale(.medium)
                                }
                                .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background {
                            Rectangle()
                                .fill(.clear)
                                .background(Material.regular)
                                .mask { Capsule() }
                        }
                        .foregroundColor(.primary)
                    })
                    .sheet(isPresented: $showChangePasswordView) {
                        ResetPasswordView(text: $email)
                            .environmentObject(viewModel)
                    }
                    .padding(.top)
                    Button(role: .destructive) {
                        showDeleteSheet.toggle()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 7) {
                                    Text("Delete Account")
                                    Spacer()
                                    FAText(iconName: "trash-can", size: 20)
                                }
                                .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background {
                            Rectangle()
                                .fill(.clear)
                                .background(Material.regular)
                                .mask { Capsule() }
                        }
                    }
                }
                .padding()
            }
            Divider()
            Button(action: {
                viewModel.updateUser(withEmail: email, username: username, fullname: fullname) { success in
                    if success {
                        showAlert.toggle()
                    } else {
                        showError.toggle()
                    }
                } completionString: { string in
                    errorMessage = string
                }
            }, label: {
                HStack {
                    Spacer()
                    Text(NSLocalizedString("save", comment: "Save"))
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
            })
            .opacity(!isEmpty ? 0.5 : 1.0)
            .disabled(!isEmpty)
            .padding()
        }
        .sheet(isPresented: $showDeleteSheet) {
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    SheetCloseButton(isPresented: $showDeleteSheet)
                }
                Spacer()
                Image(systemName: "trash")
                    .font(.system(size: 34).weight(.semibold))
                    .foregroundColor(.red)
                Text(NSLocalizedString("delete_account_confirmation_short", comment: "Are you sure you want to delete this account?"))
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
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) {
                    showDeleteConfirmation = false
                }
            } message: {
                Text("Are you sure you want to delete this user account? WARNING: THIS ACTION IS PERMANENT AND CANNOT BE UNDONE!")
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Success!"), message: Text("Your changes were saved."), dismissButton: .cancel(Text("Close")))
        }
    }
    
    func deleteAccount() {
        viewModel.deleteUser { success, errorMessage in
            if success {
                showDeleteSheet = false
                presMode.wrappedValue.dismiss()
            } else {
                showError = true
                self.errorMessage = errorMessage
            }
        }
    }
}
