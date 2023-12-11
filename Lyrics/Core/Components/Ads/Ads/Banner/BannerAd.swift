//
//  BannerAd.swift
//  Lyrics
//
//  Created by Liam Willey on 12/5/23.
//

import SwiftUI
import GoogleMobileAds
import Foundation

struct BannerAd: UIViewRepresentable {
    let adUnitID: String
    
    func makeUIView(context: Context) -> GADBannerView {
        let adView = GADBannerView(adSize: GADAdSizeBanner)
        
        adView.adUnitID = adUnitID
        adView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        adView.load(GADRequest())
        
        print(adView)
        
        return adView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        
    }
}
