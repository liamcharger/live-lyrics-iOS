//
//  BandsView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import SwiftUI

struct BandsView: View {
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CustomNavBar(title: NSLocalizedString("bands", comment: ""), showBackButton: true)
                Spacer()
                Button {
                    
                } label: {
                    
                }
            }
            .padding()
            Divider()
            if bandsViewModel.isLoadingUserBands {
                Spacer()
                ProgressView("Loading")
                Spacer()
            } else if bandsViewModel.userBands.isEmpty {
                FullscreenMessage(imageName: "circle.slash", title: NSLocalizedString("no_user_bands", comment: ""), spaceNavbar: true)
            } else {
                ScrollView {
                    VStack {
                        ForEach(bandsViewModel.userBands) { band in
                            BandRowView(band: band)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            bandsViewModel.fetchUserBands()
        }
    }
}

#Preview {
    BandsView()
}
