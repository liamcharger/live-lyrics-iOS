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
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var viewModel = AuthViewModel.shared
    
    @State var showLogoutMenu = false
    @State var showNewSong = false
    @State var showMailView = false
    @State var showProfileView = false
    @State var showSettingsView = false
    @State var showWebView = false
    @State var showPremiumView = false
    @State var showDeleteSheet = false
    @State var showRefreshDialog = false
    @State var showCannotPurchaseAlert = false
    @State var showCannotSendFeedbackAlert = false
    
    @State var result: Result<MFMailComposeResult, Error>? = nil
    
    @Binding var showMenu: Bool
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func hasPro(_ user: User) -> Bool {
        return user.hasPro ?? false
    }
    func purchase(product: Product) async {
        do {
            if try await storeKitManager.purchase(product) != nil {
                print("\(product.id) purchased successfully")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var body: some View {
        if let user = viewModel.currentUser {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(user.fullname)
                                .font(.title2.weight(.semibold))
                            if hasPro(user) {
                                Text("PRO")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 12).weight(.semibold))
                                    .padding(6)
                                    .padding(.horizontal, 2)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            }
                        }
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
                        ProfileView(user: user, isPresented: $showProfileView)
                    }
                    CloseButton {
                        showMenu = false
                    }
                }
                .padding()
                Divider()
                if mainViewModel.notifications.isEmpty {
                    FullscreenMessage(imageName: "envelope", title: "Hmm, it doesn't look like you have any new messages.")
                } else {
                    ScrollView {
                        VStack {
                            ForEach(mainViewModel.notifications) { notif in
                                NotificationRowView(notification: notif)
                            }
                        }
                        .padding()
                    }
                }
                Divider()
                Group {
                    VStack(spacing: 10) {
                        if user.showAds ?? true, !(user.hasPro ?? false), let product = storeKitManager.storeProducts.first(where: { $0.id == "remove_ads" }) {
                            Button(action: {
                                if isAuthorizedForPayments {
                                    Task {
                                        await purchase(product: product)
                                    }
                                } else {
                                    showCannotPurchaseAlert = true
                                }
                            }, label: {
                                HStack(spacing: 7) {
                                    VStack(alignment: .leading, spacing: 5) {
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
                                    // Use audio-description because of label "AD"
                                    FAText(iconName: "audio-description-slash", size: 20)
                                        .font(.body.weight(.semibold))
                                }
                                .foregroundColor(Color.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            })
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
                            if MFMailComposeViewController.canSendMail() {
                                showMailView = true
                            } else {
                                showCannotSendFeedbackAlert = true
                            }
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
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .alert(isPresented: $showCannotPurchaseAlert) {
                Alert(title: Text("Cannot Purchase"), message: Text("This item cannot be purchased due to device restrictions."), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showCannotSendFeedbackAlert) {
                Alert(title: Text("Cannot Send Feedback"), message: Text("A mail client could not be opened."), dismissButton: .default(Text("Cancel")))
            }
        }
    }
}
