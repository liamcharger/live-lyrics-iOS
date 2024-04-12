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
                .frame(height: height)
                .background(Material.regular)
                .foregroundColor(.gray)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                BannerAd(adUnitID: unitId)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: height)
        }
    }
}

#Preview {
    AdBannerView(unitId: "ca-app-pub-9538983146851531/4662411532", height: 70)
}
