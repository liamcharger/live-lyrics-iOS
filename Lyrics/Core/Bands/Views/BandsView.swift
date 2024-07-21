//
//  BandsView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import SwiftUI
import BottomSheet
import SimpleToast

struct BandsView: View {
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    @State var showNewBandSheet = false
    @State var showJoinBandSheet = false
    @State var showUserPopover = false
    @State var showToast = false
    
    @State var selectedMember: BandMember?
    @State var selectedBand: Band?
    @State var isSheetPresented = false
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavBar(title: NSLocalizedString("bands", comment: ""), showBackButton: true)
                .padding()
            Divider()
            if !NetworkManager.shared.getNetworkState() {
                FullscreenMessage(imageName: "circle.slash", title: NSLocalizedString("connect_to_internet_to_view_bands", comment: ""), spaceNavbar: true)
            } else if bandsViewModel.isLoadingUserBands {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView("Loading")
                    Spacer()
                }
                .padding()
                Spacer()
            } else if bandsViewModel.userBands.isEmpty {
                // TODO: add "what are bands?" button
                FullscreenMessage(imageName: "circle.slash", title: NSLocalizedString("no_user_bands", comment: ""), spaceNavbar: true)
            } else {
                ScrollView {
                    VStack {
                        ForEach(bandsViewModel.userBands) { band in
                            BandRowView(band: band, selectedMember: $selectedMember, selectedBand: $selectedBand, showToast: $showToast, showUserPopover: $showUserPopover, isSheetPresented: $isSheetPresented)
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
        .simpleToast(isPresented: $showToast, options: SimpleToastOptions(
            alignment: .top,
            hideAfter: 5,
            animation: Animation.bouncy(extraBounce: 0.15),
            modifierType: .slide
        )) {
            Label("The band join code has been copied to the clipboard.", systemImage: "info.circle")
                .padding()
                .background(Color.blue.opacity(0.9))
                .foregroundColor(Color.white)
                .cornerRadius(15)
                .padding()
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            bandsViewModel.fetchUserBands {}
        }
        .bottomSheet(isPresented: $showUserPopover, detents: [.medium()], onDismiss: { isSheetPresented = false }) {
            if let member = selectedMember, let band = selectedBand {
                BandMemberPopover(member: member, band: band)
            }
        }
    }
}

#Preview {
    BandsView()
}
