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
    @State var showUserPopover = false
    
    @State var selectedMember: BandMember?
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavBar(title: NSLocalizedString("bands", comment: ""), showBackButton: true)
                .padding()
            Divider()
            if bandsViewModel.isLoadingUserBands {
                HStack {
                    Spacer()
                    ProgressView("Loading")
                    Spacer()
                }
                .padding()
            } else if bandsViewModel.userBands.isEmpty {
                // TODO: add "what are bands?" button
                FullscreenMessage(imageName: "circle.slash", title: NSLocalizedString("no_user_bands", comment: ""), spaceNavbar: true)
            } else {
                ScrollView {
                    VStack {
                        ForEach(bandsViewModel.userBands) { band in
                            BandRowView(band: band, selectedMember: $selectedMember, showUserPopover: $showUserPopover)
                                .bottomSheet(isPresented: $showUserPopover, detents: [.medium()]) {
                                    if let member = selectedMember {
                                        BandMemberPopover(member: member, band: band)
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            Divider()
            VStack(spacing: 12) {
                Button {
                    showJoinBandSheet = true
                } label: {
                    HStack(spacing: 5) {
                        FAText(iconName: "plus", size: 20)
                        Text("Join a Band")
                            .font(.body.weight(.semibold))
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(Capsule())
                }
                Button {
                    showNewBandSheet = true
                } label: {
                    Text("Create a Band")
                }
            }
            .padding()
        }
        .sheet(isPresented: $showNewBandSheet) {
            NewBandView(isPresented: $showNewBandSheet)
        }
        .sheet(isPresented: $showJoinBandSheet) {
            BandJoinView(isPresented: $showJoinBandSheet)
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
