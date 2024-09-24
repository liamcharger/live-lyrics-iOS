//
//  BandsView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import SwiftUI
import BottomSheet

struct BandsView: View {
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    @State var showNewBandSheet = false
    @State var showJoinBandSheet = false
    @State var collapsedNavbarTitle = false
    
    @State var selectedBand: Band?
    
    @AppStorage("hasShownBandsIntro") var hasShownBandsIntro = false
    
    var body: some View {
        if hasShownBandsIntro {
            content
        } else {
            NewFeatureView(feature: NewFeature(title: "Bands", sections: [
                NewFeatureSection(id: 1, title: "An Easy Way to Collaborate", icon: "users", subtitle: "Bands makes it easy to share songs and folders with your band members, but with a twist: you can share song variations tailored to each member’s role inside the band."),
                NewFeatureSection(id: 2, title: "Member Roles", icon: "users", subtitle: "Assign a role to a member to give them access to a variation specifically created for that role, like piano chords for a keyboardist, or special lyrics for a backup singer.")
            ]))
        }
    }
    
    var content: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                CustomNavBar(title: NSLocalizedString("bands", comment: ""), showBackButton: true, collapsed: .constant(true), collapsedTitle: $collapsedNavbarTitle)
                    .padding()
                Divider()
                ScrollView {
                    VStack(alignment: .leading) {
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollViewOffsetPreferenceKey.self, value: [geo.frame(in: .global).minY])
                        }
                        .frame(height: 0)
                        HeaderView(NSLocalizedString("Bands", comment: ""), icon: "guitar", color: .blue, geo: geo, counter: "\(bandsViewModel.userBands.count) band\(bandsViewModel.userBands.count == 1 ? "" : "s")".uppercased())
                        // TODO: add banner ad for BandsView in AdMob
                        AdBannerView(unitId: "ca-app-pub-5671219068273297/7596037220", height: 80, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0)
                        Group {
//                            if !NetworkManager.shared.getNetworkState() {
//                                FullscreenMessage(imageName: "circle.slash", title: NSLocalizedString("connect_to_internet_to_view_bands", comment: ""), spaceNavbar: true)
//                                    .frame(maxWidth: .infinity)
//                                    .frame(height: geo.size.height / 2.2, alignment: .bottom)
//                            } else if bandsViewModel.isLoadingUserBands {
//                                ProgressView("Loading")
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                            } else {
                                VStack(spacing: 18) {
                                    HeaderActionsView([
                                        .init(title: NSLocalizedString("Join Band", comment: ""), icon: "link", scheme: .primary, action: {
                                            showJoinBandSheet = true
                                        }),
                                        .init(title: NSLocalizedString("Create Band", comment: ""), icon: "plus", scheme: .secondary, action: {
                                            showNewBandSheet = true
                                        })
                                    ])
                                    if bandsViewModel.userBands.isEmpty {
                                        // TODO: add "what are bands?" button or tip
                                        FullscreenMessage(imageName: "circle.slash", title: NSLocalizedString("no_user_bands", comment: ""), spaceNavbar: true)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: geo.size.height / 2.2, alignment: .bottom)
                                    } else {
                                        VStack {
                                            ForEach(bandsViewModel.userBands) { band in
                                                Button {
                                                    selectedBand = band
                                                } label: {
                                                    BandRowView(band: band, selectedBand: $selectedBand)
                                                }
                                            }
                                        }
                                    }
                                }
//                            }
                        }
                    }
                    .padding()
                    .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                        let animation = Animation.easeInOut(duration: 0.22)
                        
                        if value.first ?? 0 >= -20 {
                            DispatchQueue.main.async {
                                withAnimation(animation) {
                                    collapsedNavbarTitle = false
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                withAnimation(animation) {
                                    collapsedNavbarTitle = true
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showNewBandSheet) {
                NewBandView(isPresented: $showNewBandSheet)
            }
            .sheet(isPresented: $showJoinBandSheet) {
                BandJoinView(isPresented: $showJoinBandSheet)
            }
            .sheet(item: $selectedBand) { band in
                BandDetailView(band: Binding(get: {
                    band
                }, set: { band in
                    selectedBand = band
                }))
            }
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                bandsViewModel.fetchUserBands {}
            }
        }
    }
}

#Preview {
    BandsView()
}
