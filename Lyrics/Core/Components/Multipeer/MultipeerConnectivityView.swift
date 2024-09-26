//
//  MultipeerConnectivityView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/25/24.
//

import SwiftUI

struct MultipeerConnectivityView: View {
    @ObservedObject var viewModel = MultipeerConnectivityManager.shared
    @Environment(\.dismiss) var dismiss
    
    let band: Band?
    
    var body: some View {
        VStack(spacing: 0) {
            header
            if let band = band, hasSharePermissions() {
                adminContent(band: band)
            } else {
                receiverContent
            }
        }
        .onAppear(perform: setupView)
        .onDisappear(perform: deintializeView)
    }
    
    // MARK: - View Components
    
    private var header: some View {
        HStack {
            Text(!viewModel.peers.isEmpty && !viewModel.isConnected ? "Detected Devices" : "")
                .font(.system(size: 28, design: .rounded).weight(.bold))
                .multilineTextAlignment(.leading)
            Spacer()
            SheetCloseButton { dismiss() }
        }
        .padding(headerPadding)
    }
    
    private func adminContent(band: Band) -> some View {
        VStack(spacing: 4) {
            if viewModel.isConnected {
                sendingView
                    .onAppear { viewModel.sendData(MultipeerInvitation(contentId: band.joinId, uid: uid(), type: "band")) }
            } else if viewModel.transactionCompleted {
                successView(admin: true)
            } else {
                detectedPeersView
            }
        }
        .multilineTextAlignment(.center)
    }
    
    private var receiverContent: some View {
        Group {
            if viewModel.transactionCompleted {
                successView(admin: false)
                    .padding()
            } else {
                receivingView
            }
        }
    }
    
    private var sendingView: some View {
        VStack(spacing: 4) {
            Spacer()
            Text("Sending invitation...")
                .font(.title.weight(.bold))
            Text("Keep your device near the recipient's device.")
            Spacer()
            ProgressView()
            Spacer()
        }
        .padding()
    }
    
    private var detectedPeersView: some View {
        Group {
            if viewModel.peers.isEmpty {
                searchingView
            } else {
                peerListView
            }
        }
    }
    
    private var peerListView: some View {
        VStack(spacing: 0) {
            if !viewModel.peers.isEmpty && !viewModel.isConnected {
                Divider()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.peers, id: \.self) { peer in
                        Button(action: { viewModel.invitePeer(peer) }) {
                            ListRowView(title: peer.displayName, icon: "iphone")
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var searchingView: some View {
        VStack(spacing: 4) {
            Spacer()
            Text("Looking for recipients...")
                .font(.title.weight(.bold))
            Text("Make sure your device is near the recipient's device.")
            Spacer()
            ProgressView()
            Spacer()
        }
        .padding()
    }
    
    private func successView(admin: Bool) -> some View {
        VStack {
            Text("Success!")
                .font(.title.weight(.bold))
            Text(admin ? "The band was successfully shared." : "The band was successfully received.")
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 85))
                .foregroundColor(.blue)
            Spacer()
        }
        .multilineTextAlignment(.center)
    }
    
    private var receivingView: some View {
        VStack(spacing: 4) {
            Spacer()
            Text("Waiting on sender...")
                .font(.largeTitle.weight(.bold))
            Text("Keep your device near the sender's device.")
            Spacer()
            ProgressView()
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func setupView() {
        if hasSharePermissions()  {
            viewModel.startBrowsing()
        } else {
            viewModel.startAdvertising()
        }
    }
    
    private func deintializeView() {
        if hasSharePermissions()  {
            viewModel.stopBrowsing()
        } else {
            viewModel.stopAdvertising()
        }
    }
    
    private var headerPadding: EdgeInsets {
        if band == nil || (viewModel.peers.isEmpty && viewModel.isConnected) {
            return EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16)
        }
        return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    }
}
