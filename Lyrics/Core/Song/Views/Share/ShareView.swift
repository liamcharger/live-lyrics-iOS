//
//  SongShareView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/2/24.
//

import SwiftUI

struct ShareView: View {
    @Environment(\.presentationMode) var presMode
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @Binding var isDisplayed: Bool
    @State var selectedUsers = [String: String]()
    @State var searchText = ""
    @State var collaborate = false
    @State var firstSearch = true
    @State var isSendingRequest = false
    
    @State var selectedUser: User?
    
    @AppStorage("ShareView.recentSearches") var recentSearches = ""
    
    let song: Song?
    let folder: Folder?
    let networkManager = NetworkManager.shared
    let userService = UserService()
    
    var disabled: Bool {
        selectedUsers.isEmpty || !networkManager.getNetworkState() || isSendingRequest
    }
    
    init(isDisplayed: Binding<Bool>, song: Song? = nil, folder: Folder? = nil) {
        self._isDisplayed = isDisplayed
        self.song = song
        self.folder = folder
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Share")
                    .font(.title.weight(.bold))
                Spacer()
                Button {
                   let timestamp = Date()
                    guard let fromUser = authViewModel.currentUser else { return }
                    let to = Array(selectedUsers.keys)
                    let type = collaborate ? "collaborate" : "copy"
                    let toUsernames = Array(selectedUsers.values)
                    
                    var request: ShareRequest?
                    
                    if let song = song {
                        request = ShareRequest(timestamp: timestamp, from: fromUser.id ?? "", to: to, contentId: song.id ?? "", contentType: "song", contentName: song.title, type: type, toUsername: toUsernames, fromUsername: fromUser.username)
                    } else if let folder = folder {
                        request = ShareRequest(timestamp: timestamp, from: fromUser.id ?? "", to: to, contentId: folder.id ?? "", contentType: "folder", contentName: folder.title, type: type, toUsername: toUsernames, fromUsername: fromUser.username)
                    } else {
                        print("Song and folder are nil")
                    }
                    
                    if let request = request {
                        self.isSendingRequest = true
                        authViewModel.sendInviteToUser(request: request) { error in
                            if let error = error {
                                print(error.localizedDescription)
                                return
                            }
                            self.isSendingRequest = false
                            presMode.wrappedValue.dismiss()
                        }
                    } else {
                        print("Error: request is nil")
                    }
                } label: {
                    if isSendingRequest {
                        ProgressView()
                            .tint(.primary)
                            .padding(12)
                            .background(Color.blue)
                            .clipShape(Circle())
                    } else {
                        Text("Send" /* + (selectedUsers.isEmpty ? "" : " " + String(selectedUsers.count)) */)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .font(.body.weight(.semibold))
                            .clipShape(Capsule())
                    }
                }
                .opacity(disabled ? 0.5 : 1.0)
                .disabled(disabled)
                SheetCloseButton(isPresented: $isDisplayed)
            }
            .padding()
            Divider()
            if networkManager.getNetworkState() {
                CustomSearchBar(text: $searchText, imageName: "magnifyingglass", placeholder: "Search by username...")
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        if !recentSearches.components(separatedBy: ",").contains(where: {$0 == searchText}) {
                            recentSearches.append(",\(searchText)")
                        }
                        firstSearch = false
                        if searchText == "" {
                            firstSearch = true
                            authViewModel.users = []
                        } else {
                            authViewModel.fetchUsers(username: searchText)
                        }
                    }
                    .padding()
                Divider()
                if authViewModel.isLoadingUsers {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if !authViewModel.users.isEmpty || (!recentSearches.isEmpty && searchText.isEmpty) {
                        ScrollView {
                            VStack {
                                if !authViewModel.users.isEmpty {
                                    ForEach(authViewModel.users.indices, id: \.self) { index in
                                        let user = authViewModel.users[index]
                                        
                                        Button {
                                            selectedUser = user
                                            selectedUsers.removeAll()
                                            selectedUsers[user.id ?? ""] = user.username
                                        } label: {
                                            SongShareRowView(user: user, selectedUsers: $selectedUsers)
                                        }
                                    }
                                } else if !recentSearches.isEmpty {
                                    HStack {
                                        ListHeaderView(title: "Recently Searched")
                                        Spacer()
                                        Button {
                                            withAnimation(.bouncy(extraBounce: 0.1)) {
                                                self.recentSearches = ""
                                            }
                                        } label: {
                                            Text("Clear")
                                                .padding(13.5)
                                                .foregroundColor(Color.red)
                                                .background(Material.regular)
                                                .clipShape(Capsule())
                                                .font(.body.weight(.semibold))
                                        }
                                    }
                                    ForEach(recentSearches.components(separatedBy: ","), id: \.self) { search in
                                        if !search.isEmpty {
                                            Button {
                                                searchText = search
                                                authViewModel.fetchUsers(username: search)
                                            } label: {
                                                Text(search)
                                                    .font(.body.weight(.semibold))
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Material.regular)
                                                    .foregroundColor(.primary)
                                                    .clipShape(Capsule())
                                            }
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    
                                                } label: {
                                                    Label("Remove", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    } else {
                        FullscreenMessage(imageName: firstSearch ? "magnifyingglass" : "person.slash", title: {
                            if firstSearch {
                                if let song = song {
                                    return "Search for a user by their username to share '\(song.title)'."
                                } else if let folder = folder {
                                    return "Search for a user by their username to share '\(folder.title)'."
                                } else {
                                    return "Search for a user by their username to share."
                                }
                            } else {
                                return "It doesn't look like there are any users with that username."
                            }
                        }(), spaceNavbar: true)
                    }
                }
            } else {
                FullscreenMessage(imageName: "wifi.slash", title: {
                    if let song = song {
                        return "Please connect to the internet to share '\(song.title)'."
                    } else if let folder = folder {
                        return "Please connect to the internet to share '\(folder.title)'."
                    } else {
                        return "Please connect to the internet to share."
                    }
                }(), spaceNavbar: true)
            }
        }
        .onDisappear {
            authViewModel.users = []
        }
    }
}

struct FullscreenMessage: View {
    let imageName: String
    let title: String
    let spaceNavbar: Bool?
    
    init(imageName: String, title: String, spaceNavbar: Bool? = nil) {
        self.imageName = imageName
        self.title = title
        self.spaceNavbar = spaceNavbar
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: imageName)
                .font(.system(size: 35).weight(.semibold))
            Text(title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            Spacer()
            if spaceNavbar != nil {
                Spacer()
                    .frame(height: 35)
            }
        }
        .padding()
        .foregroundColor(.gray)
    }
}

#Preview {
    ShareView(isDisplayed: .constant(true), song: Song.song)
}
