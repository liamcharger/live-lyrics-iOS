//
//  SongShareDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/2/24.
//

import SwiftUI

enum ShareRequestType {
    case outgoing
    case incoming
}

struct SongShareDetailView: View {
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    @State var collapsedTitle = false
    @State var isLoading = false
    @State var loadingId = ""
    
    let userService = UserService()
    let songService = SongService()
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                CustomNavBar(title: NSLocalizedString("share_invites", comment: ""), navType: .detail, showBackButton: true, collapsed: .constant(false), collapsedTitle: $collapsedTitle)
                    .padding()
                Divider()
                if mainViewModel.isLoadingInvites {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ScrollViewOffsetPreferenceKey.self, value: [geo.frame(in: .global).minY])
                            }
                            .frame(height: 0)
                            HeaderView("Share \nInvites", icon: "users", color: .blue, geo: geo, counter: "\(mainViewModel.incomingShareRequests.count) incoming, \(mainViewModel.outgoingShareRequests.count) outgoing".uppercased())
                            VStack(spacing: 18) {
                                if mainViewModel.outgoingShareRequests.isEmpty && mainViewModel.incomingShareRequests.isEmpty {
                                    FullscreenMessage(imageName: "circle.slash", title: NSLocalizedString("no_share_invites", comment: ""))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: geo.size.height / 2.2, alignment: .bottom)
                                } else if !NetworkManager.shared.getNetworkState() {
                                    FullscreenMessage(imageName: "wifi.slash", title: NSLocalizedString("connect_to_internet_to_view_share_invites", comment: ""))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: geo.size.height / 2.2, alignment: .bottom)
                                } else {
                                    VStack {
                                        ListHeaderView(title: NSLocalizedString("outgoing", comment: ""))
                                        ForEach(mainViewModel.outgoingShareRequests) { request in
                                            rowView(request: request, type: .outgoing)
                                        }
                                    }
                                    VStack {
                                        ListHeaderView(title: NSLocalizedString("incoming", comment: ""))
                                        ForEach(mainViewModel.incomingShareRequests) { request in
                                            rowView(request: request, type: .incoming)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                            let animation = Animation.easeInOut(duration: 0.22)
                            
                            if value.first ?? 0 >= -40 {
                                DispatchQueue.main.async {
                                    withAnimation(animation) {
                                        collapsedTitle = false
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    withAnimation(animation) {
                                        collapsedTitle = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }
    
    func rowView(request: ShareRequest, type: ShareRequestType) -> some View {
        return VStack {
            HStack {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 5) {
                        Text(request.contentName)
                            .font(.title2.weight(.semibold))
                        Text(request.contentType.uppercased())
                            .padding(6)
                            .padding(.horizontal, 2)
                            .background(Material.thin)
                            .font(.system(size: 11).weight(.medium))
                            .clipShape(Capsule())
                    }
                    if type == .incoming {
                        Text(request.fromUsername)
                    }
                }
                Spacer()
                if type == .outgoing {
                    HStack(spacing: 8) {
                        Text({
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MM/dd/yyyy"
                            return dateFormatter.string(from: request.timestamp)
                        }())
                        Button {
                            self.loadingId = request.id ?? ""
                            self.isLoading = true
                            mainViewModel.declineInvite(incomingReqColUid: request.to.first, request: request) {
                                self.loadingId = ""
                                self.isLoading = false
                            }
                        } label: {
                            Image(systemName: "trash")
                                .padding(8)
                                .font(.system(size: 17).weight(.semibold))
                                .background(Material.thin)
                                .foregroundColor(.red)
                                .clipShape(Circle())
                        }
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.5 : 1)
                    }
                } else {
                    HStack(spacing: 6) {
                        if !isLoading || loadingId != request.id {
                            Button {
                                self.loadingId = request.id ?? ""
                                self.isLoading = true
                                mainViewModel.acceptInvite(request: request) {
                                    self.loadingId = ""
                                    self.isLoading = false
                                }
                            } label: {
                                Image(systemName: "checkmark")
                                    .padding(12)
                                    .font(.body.weight(.semibold))
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.5 : 1)
                            Button {
                                self.loadingId = request.id ?? ""
                                self.isLoading = true
                                mainViewModel.declineInvite(request: request) {
                                    self.loadingId = ""
                                    self.isLoading = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .padding(12)
                                    .font(.body.weight(.semibold))
                                    .background(Material.thin)
                                    .foregroundColor(.primary)
                                    .clipShape(Circle())
                            }
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.5 : 1)
                        } else if loadingId == request.id {
                            ProgressView()
                        }
                    }
                }
            }
            if type == .outgoing {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, -16)
                    Text({
                        var users = ""
                        for to in request.toUsername {
                            users += "\(users.isEmpty ? "" : ", ")\(to)"
                        }
                        return users.isEmpty ? "Loading..." : "To: " + users
                    }())
                    .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Material.regular)
        .foregroundColor(.primary)
        .cornerRadius(20)
    }
}

#Preview {
    SongShareDetailView()
        .onAppear {
            MainViewModel.shared.isLoadingInvites = false
        }
}
