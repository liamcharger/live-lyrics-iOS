//
//  MenuView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import SwiftUI
import MessageUI
import StoreKit
import FASwiftUI
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
    @State var showPaywall = false
    
    @State var result: Result<MFMailComposeResult, Error>? = nil
    
    @Binding var showMenu: Bool
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    var body: some View {
        if let user = viewModel.currentUser {
            VStack(spacing: 10) {
                // MARK: Navbar
                HStack(alignment: .center, spacing: 10) {
                    // MARK: User info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            //                            if viewModel.currentUser?.hasSubscription ?? false {
                            //                                Image(systemName: "crown")
                            //                                    .foregroundColor(.yellow)
                            //                            }
                            Text(user.fullname)
                                .font(.title2.weight(.semibold))
                        }
                        Text("@\(user.username)")
                            .foregroundColor(Color.gray)
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
                if storeKitManager.purchasedProducts.isEmpty {
                    //                    HStack {
                    //                        VStack(alignment: .leading, spacing: 16) {
                    //                            HStack {
                    //                                Image(systemName: "crown")
                    //                                Text("Remove Ads")
                    //                                Spacer()
                    //                            }
                    //                            .padding(.top, 12)
                    //                            .font(.title2.weight(.bold))
                    HStack {
                        ForEach(storeKitManager.storeProducts, id: \.self) { product in
                            Button {
                                showPaywall.toggle()
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
                            .bottomSheet(isPresented: $showPaywall, detents: [.medium()]) {
                                AdFreeConfirmationView(isDisplayed: $showPaywall)
                                    .environmentObject(storeKitManager)
                            }
                        }
                    }
                    //                        }
                    //                    }
                    //                    .frame(maxWidth: .infinity)
                    //                    .padding(12)
                    //                    .background {
                    //                        Rectangle()
                    //                            .fill(.clear)
                    //                            .background(Material.regular)
                    //                            .mask { RoundedRectangle(cornerRadius: 15, style: .continuous) }
                    //                    }
                    //                    .foregroundColor(Color("Color"))
                }
                Spacer()
                if storeKitManager.purchasedProducts.isEmpty {
                    AdBannerView(unitId: "ca-app-pub-9538983146851531/2834324540", height: 50)
                        .padding(.bottom, 6)
                }
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
                            .foregroundColor(Color("Color"))
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
                    .foregroundColor(Color("Color"))
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
                            .foregroundColor(Color("Color"))
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
                    .foregroundColor(Color("Color"))
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
                    .background {
                        Rectangle()
                            .fill(.clear)
                            .background(.blue)
                            .mask { Capsule() }
                    }
                })
                .opacity(!MFMailComposeViewController.canSendMail() ? 0.5 : 1.0)
                .disabled(!MFMailComposeViewController.canSendMail())
                .sheet(isPresented: $showMailView) {
                    MailView(subject: "Live Lyrics Feedback", to: "chargertech.help@gmail.com", result: self.$result)
                }
                // Logout Button
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
                    .background {
                        Rectangle()
                            .fill(.clear)
                            .background(Color.red)
                            .mask { Capsule() }
                    }
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
