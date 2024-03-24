//
//  AdBannerView.swift
//  Lyrics
//
//  Created by Liam Willey on 12/6/23.
//

import SwiftUI

struct AdBannerView: View {
    @EnvironmentObject var storeKitManager: StoreKitManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let unitId: String
    let height: CGFloat
    
    var body: some View {
        if storeKitManager.purchasedProducts.isEmpty {
            ZStack {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(NSLocalizedString("loading_ads", comment: "Loading Ads..."))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Material.regular)
                .foregroundColor(.gray)
                .clipShape(Capsule())
                BannerAd(adUnitID: unitId)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: height)
        }
    }
}

#Preview {
    AdBannerView(unitId: "ca-app-pub-9538983146851531/4662411532", height: 50)
}
