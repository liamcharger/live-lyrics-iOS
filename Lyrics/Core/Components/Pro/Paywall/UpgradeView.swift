//
//  UpgradeView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/31/24.
//

import SwiftUI
import StoreKit

struct UpgradeView: View {
    @Environment(\.presentationMode) var presMode
    
    @AppStorage("showUpgradeSheet") var showUpgradeSheet: Bool = true
    
    @ObservedObject var storeKitManager = StoreKitManager.shared
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    @State var showError = false
    @State var showCannotPurchaseAlert = false
    
    let features = [
        NSLocalizedString("ad_free_experience", comment: ""),
        NSLocalizedString("access_to_worlds_largest_lyric_database", comment: ""),
        NSLocalizedString("access_to_tuner", comment: ""),
        NSLocalizedString("world_of_worlds_at_your_fingertips", comment: ""),
        NSLocalizedString("support_the_developers", comment: "")
    ]
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func purchase(product: Product) async {
        do {
            if try await storeKitManager.purchase(product) != nil {
                print("\(product.id) purchased successfully")
                showUpgradeSheet = false
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 34) {
                    Group {
                        Text("Yes, there's a \n") + Text("pro").fontWeight(.black) + Text(" plan.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.largeTitle.weight(.bold))
                    // TODO: replace with variety of icons
                    HStack {
                        FAText(iconName: "rocket", size: 45)
                            .foregroundColor(.red)
                        Spacer()
                        FAText(iconName: "rocket", size: 45)
                        Spacer()
                        FAText(iconName: "rocket", size: 45)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 10)
                    Text("We know, yet another subscription to pay for every month. But...with this one you get:")
                        .font(.system(size: 25).weight(.semibold))
                    VStack(spacing: 10) {
                        ForEach(features, id: \.self) { feature in
                            let showAds = authViewModel.currentUser?.showAds ?? true
                            
                            // Show the feature if it's not "ad-free" or if ads are still shown
                            if feature != NSLocalizedString("ad_free_experience", comment: "") || showAds {
                                HStack(spacing: 12) {
                                    FAText(iconName: "circle-check", size: 20)
                                        .foregroundColor(.blue)
                                    Text(feature)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Material.thin)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 145)
            }
            VStack(spacing: 12) {
                LiveLyricsButton("Subscribe for $4.99/mo") {
                    if let product = storeKitManager.storeProducts.first(where: { $0.id == "pro.monthly" }) {
                        if isAuthorizedForPayments {
                            Task {
                                await purchase(product: product)
                            }
                        } else {
                            showCannotPurchaseAlert = true
                        }
                    } else {
                        showError = true
                    }
                }
                Button {
                    showUpgradeSheet = false
                    presMode.wrappedValue.dismiss()
                } label: {
                    Text("Nah, I'll miss out")
                }
            }
            .padding()
            .padding(.bottom)
            .frame(maxWidth: .infinity)
            .background(Material.ultraThin)
        }
        .edgesIgnoringSafeArea(.bottom)
        .alert(isPresented: $showCannotPurchaseAlert) {
            Alert(title: Text("Cannot Purchase"), message: Text("This item cannot be purchased due to device restrictions."), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text("There was an unknown error while processing your request."), dismissButton: .default(Text("Cancel")))
        }
    }
}

#Preview {
    UpgradeView()
}
