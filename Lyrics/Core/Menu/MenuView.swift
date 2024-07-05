//
//  MenuView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import SwiftUI
import MessageUI
import StoreKit
import BottomSheet

struct MenuView: View {
    @Environment(\.presentationMode) var presMode
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    @State var showLogoutMenu = false
    @State var showNewSong = false
    @State var showMailView = false
    @State var showProfileView = false
    @State var showSettingsView = false
    @State var showWebView = false
    @State var showPremiumView = false
    @State var showDeleteSheet = false
    @State var showRefreshDialog = false
    
    @State var result: Result<MFMailComposeResult, Error>? = nil
    
    @Binding var showMenu: Bool
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func purchaseSubscription(product: Product) async {
        do {
            if try await storeKitManager.purchase(product) != nil {
                print("Product purchased successfully!")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var body: some View {
        if let user = viewModel.currentUser {
            VStack(spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(user.fullname)
                            .font(.title2.weight(.semibold))
                        HStack(spacing: 4) {
                            Text(user.username)
                            Text("#" + viewModel.uniqueUserID)
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(Color.gray)
                    }
                    .onTapGesture {
                        #if DEBUG
                        if let id = user.id {
                            UIPasteboard.general.string = id
                        }
                        #endif
                    }
                    .padding([.top, .bottom, .trailing])
                    Spacer()
                    Button(action: {showProfileView.toggle()}) {
                        FAText(iconName: "pen", size: 18)
                            .imageScale(.medium)
                            .padding(12)
                            .font(.body.weight(.bold))
                            .foregroundColor(.primary)
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                    .sheet(isPresented: $showProfileView) {
                        ProfileView(user: user, showProfileView: $showProfileView)
                            .environmentObject(viewModel)
                    }
                    SheetCloseButton(isPresented: $showMenu)
                }
                Divider()
                    .padding(.horizontal, -16)
                    .padding(.bottom, 12)
                if let currentUser = viewModel.currentUser, currentUser.showAds ?? true {
                    HStack {
                        ForEach(storeKitManager.storeProducts, id: \.self) { product in
                            Button {
                                Task {
                                    await purchaseSubscription(product: product)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(product.displayName)
                                            .font(.body.weight(.semibold))
                                        HStack(alignment: .center, spacing: 8) {
                                            Text(product.displayPrice)
                                            Rectangle()
                                                .frame(width: 15, height: 1.2, alignment: .center)
                                            Text("One-Time Purchase")
                                        }
                                        .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            .disabled(!isAuthorizedForPayments)
                            .opacity(!isAuthorizedForPayments ? 0.5 : 1)
                        }
                    }
                }
                Spacer()
                Divider()
                    .padding(.horizontal, -16)
                    .padding(.bottom, 12)
                AdBannerView(unitId: "ca-app-pub-5671219068273297/9309817108", height: 80, paddingTop: 0, paddingLeft: 0, paddingBottom: 6, paddingRight: 0)
                Button(action: {
                    showWebView.toggle()
                }, label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 7) {
                                Text("Privacy Policy")
                                    .fontWeight(.semibold)
                                Spacer()
                                FAText(iconName: "files", size: 20)
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Material.regular)
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                })
                .sheet(isPresented: $showWebView) {
                    WebView()
                }
                Button(action: {
                    showSettingsView.toggle()
                }, label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 7) {
                                Text("Settings")
                                    .fontWeight(.semibold)
                                Spacer()
                                FAText(iconName: "gear", size: 20)
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Material.regular)
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                })
                .sheet(isPresented: $showSettingsView) {
                    SettingsView(user: user)
                }
                Button(action: {
                    showMailView.toggle()
                }, label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 7) {
                                Text("Send Feeback")
                                    .fontWeight(.semibold)
                                Spacer()
                                FAText(iconName: "envelope", size: 20)
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundColor(Color.white)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue)
                    .clipShape(Capsule())
                })
                .opacity(!MFMailComposeViewController.canSendMail() ? 0.5 : 1.0)
                .disabled(!MFMailComposeViewController.canSendMail())
                .sheet(isPresented: $showMailView) {
                    MailView(subject: "Live Lyrics Feedback", to: "chargertech.help@gmail.com", result: self.$result)
                }
                Button(action: {
                    showDeleteSheet.toggle()
                }, label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 7) {
                                Text("Logout")
                                    .fontWeight(.semibold)
                                Spacer()
                                FAText(iconName: "square-arrow-right", size: 20)
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundColor(Color.white)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.red)
                    .clipShape(Capsule())
                })
                .confirmationDialog("Are you sure you want to log out? This action cannot be undone.", isPresented: $showDeleteSheet, titleVisibility: .visible) {
                    Button("Logout", role: .destructive) {
                        viewModel.signOut()
                        showMenu = false
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(showMenu: .constant(true))
    }
}
