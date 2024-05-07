//
//  SongShareView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/2/24.
//

import SwiftUI

struct UserToShare: Codable {
    var id: String?
    var username: String
    var appVersion: String?
}

struct ShareView: View {
    @Environment(\.presentationMode) var presMode
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var mainViewModel = MainViewModel.shared
    
    @Binding var isDisplayed: Bool
    
    @State var selectedUsers = [UserToShare]()
    @State var selectedVariations = [SongVariation]()
    @State var songVariations = [SongVariation]()
    @State var searchText = ""
    @State var collaborate = false
    @State var firstSearch = true
    @State var isSendingRequest = false
    @State var readOnly = false
    
    @State var selectedUser: User?
    
    @AppStorage("ShareView.recentSearches") var recentSearches = ""
    
    let song: Song?
    let folder: Folder?
    let networkManager = NetworkManager.shared
    let userService = UserService()
    let defaultVariationId = SongVariation.defaultId
    
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
            VStack(spacing: 12) {
                HStack {
                    Text("Share")
                        .font(.title.weight(.bold))
                    Spacer()
                    Button {
                        let timestamp = Date()
                        guard let fromUser = authViewModel.currentUser else { return }
                        let toUsernames = selectedUsers.map { $0.username }
                        let type = collaborate ? "collaborate" : "copy"
                        
                        var request: ShareRequest?
                        
                        if let song = song {
                            let toUserIds = selectedUsers.compactMap { $0.id }
                            request = ShareRequest(timestamp: timestamp, from: fromUser.id ?? "", to: toUserIds, contentId: song.id ?? "", contentType: "song", contentName: song.title, type: type, toUsername: toUsernames, fromUsername: fromUser.username, songVariations: selectedVariations.isEmpty ? nil : selectedVariations.compactMap({ $0.id }), readOnly: readOnly)
                        } else if let folder = folder {
                            let toUserIds = selectedUsers.compactMap { $0.id }
                            request = ShareRequest(timestamp: timestamp, from: fromUser.id ?? "", to: toUserIds, contentId: folder.id ?? "", contentType: "folder", contentName: folder.title, type: type, toUsername: toUsernames, fromUsername: fromUser.username, readOnly: readOnly)
                        } else {
                            print("Song and folder are nil")
                        }
                        if let request = request {
                            self.isSendingRequest = true
                            authViewModel.sendInviteToUser(request: request, includeDefault: selectedVariations.contains(where: { $0.title == defaultVariationId})) { error in
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
                if let userToShare = selectedUsers.first,
                {
                    if let appVersion = userToShare.appVersion, !appVersion.isEmpty {
                        let versionComponents = appVersion.split(separator: ".").compactMap { Int($0) }
                        let major = versionComponents[0]
                        let minor = versionComponents[1]
                        
                        return major < 2 || (major == 2 && minor < 3)
                    }
                    
                    return true
                }() {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 23).weight(.semibold))
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading) {
                            Text("Make sure that ") +
                            Text(userToShare.username)
                                .font(.body.weight(.bold))
                            + Text(" has version \(collaborate ? "2.4" : "2.3") or newer of the app.")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Material.regular)
                    .foregroundColor(.primary)
                    .cornerRadius(20)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.yellow, lineWidth: 2.5)
                    }
                }
            }
            .padding()
            Divider()
            if !songViewModel.isLoadingVariations && !songVariations.contains(where: { $0.title == "noVariations" }) {
                HStack {
                    Text("Including variation\(selectedVariations.count > 1 ? "s" : ""):")
                    Spacer()
                    Menu {
                        Button {
                            if selectedVariations.contains(where: { $0.title == defaultVariationId}) {
                                if selectedVariations.count >= 2 {
                                    self.selectedVariations.remove(at: selectedVariations.firstIndex(where: {$0.title == defaultVariationId})!)
                                }
                            } else {
                                self.selectedVariations.append(SongVariation(title: defaultVariationId, lyrics: "", songUid: "", songId: ""))
                            }
                        } label: {
                            Label("Default", systemImage: selectedVariations.contains(where: { $0.title == defaultVariationId}) ? "checkmark" : "")
                        }
                        Divider()
                        ForEach(songVariations, id: \.id) { variation in
                            Button {
                                if selectedVariations.contains(where: { $0.id ?? "" == variation.id ?? "" }) {
                                    if selectedVariations.count >= 2 {
                                        self.selectedVariations.remove(at: selectedVariations.firstIndex(where: {$0.id ?? "" == variation.id ?? ""})!)
                                    }
                                } else {
                                    self.selectedVariations.append(variation)
                                }
                            } label: {
                                Label(variation.title, systemImage: selectedVariations.contains(where: { $0.id ?? "" == variation.id ?? "" }) ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text({
                                if selectedVariations.isEmpty { 
                                    return "Default"
                                } else {
                                    if selectedVariations.count == 1 {
                                        let title = selectedVariations.first?.title ?? ""
                                        
                                        if title == defaultVariationId {
                                            return "Default"
                                        } else {
                                            return title
                                        }
                                    } else {
                                        return "Multiple"
                                    }
                                }
                            }())
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                }
                .padding()
                Divider()
            }
            VStack(spacing: 16) {
                HStack {
                    Text("Type:")
                    Spacer()
                    Menu {
                        Button(action: {
                            collaborate = true
                        }, label: {
                            Label("Collaborate", systemImage: collaborate ? "checkmark"  : "")
                        })
                        Button(action: {
                            collaborate = false
                        }, label: {
                            Label("Send Copy", systemImage: !collaborate ? "checkmark"  : "")
                        })
                    } label: {
                        HStack(spacing: 5) {
                            Text(collaborate ? "Collaborate" : "Send Copy")
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                }
                if collaborate {
                    HStack {
                        Text("Read Only:")
                        Spacer()
                        Toggle("", isOn: $readOnly).labelsHidden()
                    }
                }
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
                                            
                                            if let userId = user.id {
                                                if let existingIndex = selectedUsers.firstIndex(where: { $0.id == userId && $0.username == user.username }) {
                                                    selectedUsers.remove(at: existingIndex)
                                                } else {
                                                    selectedUsers.append(UserToShare(id: userId, username: user.username, appVersion: user.currentVersion))
                                                }
                                            }
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
                                                    if let index = recentSearches.components(separatedBy: ",").firstIndex(of: search) {
                                                        var updatedSearches = recentSearches.components(separatedBy: ",")
                                                        updatedSearches.remove(at: index)
                                                        recentSearches = updatedSearches.joined(separator: ",")
                                                    }
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
        .onAppear {
            authViewModel.users = []
            if let song = song {
                songViewModel.fetchSongVariations(song: song) { variations in
                    self.songVariations = variations
                    var selectedVariations = variations
                    selectedVariations.append(SongVariation(title: SongVariation.defaultId, lyrics: "", songUid: "", songId: ""))
                    self.selectedVariations = selectedVariations
                }
            }
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
