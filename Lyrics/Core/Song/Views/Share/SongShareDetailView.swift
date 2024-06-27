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
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State var isLoadingAccept = false
    @State var isLoadingDecline = false
    @State var loadingIdAccept = ""
    @State var loadingIdDecline = ""
    
    let userService = UserService()
    let songService = SongService()
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavBar(title: NSLocalizedString("share_invites", comment: ""), navType: .detail)
                .padding()
            Divider()
            if NetworkManager.shared.getNetworkState() {
                if mainViewModel.isLoadingInvites {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if mainViewModel.outgoingShareRequests.isEmpty && mainViewModel.incomingShareRequests.isEmpty {
                        FullscreenMessage(imageName: "circle.slash", title: NSLocalizedString("no_share_invites", comment: ""), spaceNavbar: true)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
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
                            .padding()
                        }
                    }
                }
            } else {
                FullscreenMessage(imageName: "wifi.slash", title: NSLocalizedString("connect_to_internet_to_view_share_invites", comment: ""), spaceNavbar: true)
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
                            self.loadingIdDecline = request.id ?? ""
                            self.isLoadingDecline = true
                            // Update when multiple users are supported
                            mainViewModel.declineInvite(incomingReqColUid: request.to.first, request: request) {
                                self.loadingIdDecline = ""
                                self.isLoadingDecline = false
                            }
                        } label: {
                            Image(systemName: "trash")
                                .padding(8)
                                .font(.system(size: 17).weight(.semibold))
                                .background(Material.thin)
                                .foregroundColor(.red)
                                .clipShape(Circle())
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        if !isLoadingAccept && loadingIdAccept != request.id {
                            Button {
                                self.loadingIdAccept = request.id ?? ""
                                self.isLoadingAccept = true
                                mainViewModel.acceptInvite(request: request) {
                                    self.loadingIdAccept = ""
                                    self.isLoadingAccept = false
                                }
                            } label: {
                                Image(systemName: "checkmark")
                                    .padding(12)
                                    .font(.body.weight(.semibold))
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            Button {
                                self.loadingIdDecline = request.id ?? ""
                                self.isLoadingDecline = true
                                mainViewModel.declineInvite(request: request) {
                                    self.loadingIdDecline = ""
                                    self.isLoadingDecline = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .padding(12)
                                    .font(.body.weight(.semibold))
                                    .background(Material.thin)
                                    .foregroundColor(.primary)
                                    .clipShape(Circle())
                            }
                        } else {
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
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    SongShareDetailView()
        .environmentObject(AuthViewModel())
}
