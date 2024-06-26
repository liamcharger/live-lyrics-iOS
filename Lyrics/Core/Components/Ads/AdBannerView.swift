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
    
    var paddingTop: CGFloat
    var paddingLeft: CGFloat
    var paddingBottom: CGFloat
    var paddingRight: CGFloat
    
    var body: some View {
        if let currentUser = authViewModel.currentUser, currentUser.showAds ?? true {
            ZStack {
                HStack(spacing: 7) {
                    ProgressView()
                    Text("Loading Ads...")
                        .foregroundColor(.gray)
                }
                BannerAd(adUnitID: unitId)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .padding(.top, paddingTop)
                    .padding(.bottom, paddingBottom)
                    .padding(.trailing, paddingRight)
                    .padding(.leading, paddingLeft)
            }
        }
    }
}
