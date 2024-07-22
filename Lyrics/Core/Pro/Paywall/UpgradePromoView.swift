//
//  UpgradePromoView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/21/24.
//

import SwiftUI

struct UpgradePromoView: View {
    @AppStorage("showUpgradeSheet") var showUpgradeSheet: Bool = true
    
    let features = [
        NSLocalizedString("ad_free_experience", comment: ""),
        NSLocalizedString("access_to_worlds_largest_lyric_database", comment: ""),
        NSLocalizedString("access_to_tuner", comment: ""),
        NSLocalizedString("world_of_worlds_at_your_fingertips", comment: ""),
        NSLocalizedString("support_the_developers", comment: "")
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
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
                .padding()
                .padding(.bottom, 125)
            }
            VStack(spacing: 12) {
                Button {
                    
                } label: {
                    Text("Subscribe for $4.99/mo")
                        .modifier(NavButtonViewModifier())
                }
                Button {
                    showUpgradeSheet = false
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
    }
}

#Preview {
    UpgradePromoView()
}
