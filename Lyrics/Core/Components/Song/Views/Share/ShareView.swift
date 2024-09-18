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
    var notificationToken: String?
}

struct ShareView: View {
    @Environment(\.presentationMode) var presMode
    
    @ObservedObject var authViewModel = AuthViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var networkManager = NetworkManager.shared
    
    @Binding var isDisplayed: Bool
    
    @State var selectedUsers = [UserToShare]()
    @State var selectedVariations = [SongVariation]()
    @State var songVariations = [SongVariation]()
    @State var searchText = ""
    @State var collaborate = true
    @State var firstSearch = true
    @State var isSendingRequest = false
    @State var readOnly = false
    
    @State var selectedUser: User?
    @State var selectedBand: Band?
    
    @AppStorage("ShareView.recentSearches") var recentSearches = ""
    
    @FocusState var isFocused: Bool
    
    let song: Song?
    let folder: Folder?
    let defaultVariationId = SongVariation.defaultId
    
    var disabled: Bool {
        (selectedUsers.isEmpty && selectedBand == nil) || !networkManager.getNetworkState() || isSendingRequest
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
                        let dispatch = DispatchGroup()
                        guard let fromUser = authViewModel.currentUser else { return }
                        guard let fromUserId = authViewModel.currentUser?.id else { return }
                        let toUsernames = selectedUsers.map { $0.username }
                        let toUserIds = selectedUsers.compactMap { $0.id }
                        let type = collaborate ? "collaborate" : "copy"
                        
                        var request: ShareRequest?
                        var users = [ShareUser]()
                        
                        if let selectedBand = selectedBand {
                            let toUserIds = selectedBand.members
                            
                            dispatch.enter()
                            bandsViewModel.fetchBandMembers(selectedBand) { members in
                                dispatch.leave()
                                request = ShareRequest(timestamp: timestamp, from: fromUserId, to: toUserIds, contentId: (song?.id ?? (folder?.id!))!, contentType: song == nil ? "folder" : "song", contentName: song?.title ?? (folder?.title)!, type: type, toUsername: [selectedBand.name], fromUsername: fromUser.username, songVariations: [SongVariation.defaultId], readOnly: readOnly, bandId: selectedBand.id!)
                                
                                for member in members.filter({ $0.uid != fromUserId }) {
                                    users.append(ShareUser(uid: member.uid, songVariations: {
                                        if selectedVariations.contains(where: { $0.title == "byRole" }) {
                                            if song != nil {
                                                var uniqueVariations: [String] = []
                                                
                                                for realVariation in songVariations {
                                                    if realVariation.roleId ?? "" == member.roleId ?? SongVariation.defaultId {
                                                        uniqueVariations.append(realVariation.id ?? "")
                                                    }
                                                }
                                                
                                                return uniqueVariations.isEmpty ? [SongVariation.defaultId] : uniqueVariations
                                            } else {
                                                return selectedVariations.compactMap({ $0.title })
                                            }
                                        } else if selectedVariations.contains(where: { $0.title == SongVariation.defaultId }) {
                                            return [SongVariation.defaultId]
                                        } else {
                                            return []
                                        }
                                    }(), fcmId: member.fcmId))
                                }
                            }
                        } else {
                            dispatch.enter()
                            if let song = song {
                                request = ShareRequest(timestamp: timestamp, from: fromUserId, to: toUserIds, contentId: song.id ?? "", contentType: "song", contentName: song.title, type: type, toUsername: toUsernames, fromUsername: fromUser.username, songVariations: [SongVariation.defaultId], readOnly: readOnly)
                                
                                for user in selectedUsers {
                                    users.append(ShareUser(uid: user.id!, songVariations: selectedVariations.isEmpty ? [SongVariation.defaultId] : selectedVariations.compactMap({ $0.id }), fcmId: user.notificationToken))
                                }
                            } else if let folder = folder {
                                request = ShareRequest(timestamp: timestamp, from: fromUserId, to: toUserIds, contentId: folder.id ?? "", contentType: "folder", contentName: folder.title, type: type, toUsername: toUsernames, fromUsername: fromUser.username, readOnly: readOnly)
                                
                                for user in selectedUsers {
                                    users.append(ShareUser(uid: user.id!, songVariations: selectedVariations.compactMap({ $0.title }), fcmId: user.notificationToken))
                                }
                            }
                            dispatch.leave()
                        }
                        dispatch.notify(queue: .main) {
                            if let request = request {
                                self.isSendingRequest = true
                                authViewModel.sendInviteToUser(request: request, users: users, includeDefault: selectedVariations.contains(where: { $0.title == defaultVariationId})) { error in
                                    if let error = error {
                                        print(error.localizedDescription)
                                        return
                                    }
                                    self.isSendingRequest = false
                                    presMode.wrappedValue.dismiss()
                                }
                            }
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
                    SheetCloseButton {
                        isDisplayed = false
                    }
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
                            + Text(" has version \(collaborate ? "2.4" : "2.3") or newer of the app to receive this request.")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Material.regular)
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.yellow, lineWidth: 2.5)
                    }
                }
            }
            .padding()
            Divider()
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
                        Text("Read only:")
                        Spacer()
                        Toggle("", isOn: $readOnly).labelsHidden()
                    }
                }
            }
            .padding()
            Divider()
            if (folder == nil ? !songViewModel.isLoadingVariations && !songVariations.contains(where: { $0.title == "noVariations" }) && songVariations.count >= 1 : true) && collaborate {
                HStack {
                    Text("Including variation\(selectedVariations.count > 1 || selectedVariations.isEmpty ? "s" : ""):")
                    Spacer()
                    Menu {
                        Button {
                            self.selectedVariations.removeAll()
                        } label: {
                            Label(NSLocalizedString("All", comment: ""), systemImage: selectedVariations.isEmpty ? "checkmark" : "")
                        }
                        Button {
                            if selectedVariations.contains(where: { $0.title == defaultVariationId}) {
                                if selectedVariations.count >= 2 {
                                    self.selectedVariations.remove(at: selectedVariations.firstIndex(where: {$0.title == defaultVariationId})!)
                                }
                            } else {
                                self.selectedVariations.append(SongVariation(title: defaultVariationId, lyrics: "", songUid: "", songId: ""))
                            }
                        } label: {
                            Label(NSLocalizedString("Main", comment: ""), systemImage: selectedVariations.contains(where: { $0.title == defaultVariationId}) ? "checkmark" : "")
                        }
                        if selectedBand != nil {
                            Button {
                                self.selectedVariations.removeAll()
                                self.selectedVariations.append(SongVariation(title: "byRole", lyrics: "", songUid: "", songId: ""))
                            } label: {
                                Label(NSLocalizedString("By Role", comment: ""), systemImage: selectedVariations.contains(where: { $0.title == "byRole"}) ? "checkmark" : "")
                            }
                        }
                        if folder == nil {
                            Divider()
                            ForEach(songVariations, id: \.id) { variation in
                                Button {
                                    if let byRole = selectedVariations.firstIndex(where: { $0.title == "byRole" }) {
                                        self.selectedVariations.remove(at: byRole)
                                    }
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
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text({
                                if selectedVariations.isEmpty {
                                    return NSLocalizedString("All", comment: "")
                                } else {
                                    if selectedVariations.count == 1 {
                                        let title = selectedVariations.first?.title ?? ""
                                        
                                        if title == defaultVariationId {
                                            return NSLocalizedString("Main", comment: "")
                                        } else if title == "byRole" {
                                            return NSLocalizedString("By Role", comment: "")
                                        } else {
                                            return title
                                        }
                                    } else {
                                        return NSLocalizedString("multiple", comment: "")
                                    }
                                }
                            }())
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                }
                .padding()
            }
            Divider()
            if networkManager.getNetworkState() {
                CustomSearchBar(text: $searchText, imageName: "magnifyingglass", placeholder: NSLocalizedString("search_by_username", comment: ""))
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        firstSearch = false
                        if searchText == "" {
                            firstSearch = true
                            authViewModel.users = []
                        } else {
                            authViewModel.fetchUsers(username: searchText, filterCurrentUser: true) {
                                if !recentSearches.components(separatedBy: ",").contains(where: {$0 == searchText}) && !authViewModel.users.isEmpty {
                                    recentSearches.append(",\(searchText)")
                                }
                            }
                        }
                    }
                    .padding()
                Divider()
                if authViewModel.isLoadingUsers || bandsViewModel.isLoadingBands {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if !authViewModel.users.isEmpty || (!recentSearches.isEmpty && searchText.isEmpty) && firstSearch {
                        ScrollView {
                            VStack {
                                if !bandsViewModel.bands.isEmpty && authViewModel.users.isEmpty {
                                    VStack {
                                        HStack {
                                            ListHeaderView(title: NSLocalizedString("bands", comment: ""))
                                            Spacer()
                                        }
                                        ForEach(bandsViewModel.bands) { band in
                                            Button {
                                                if let selectedBand = selectedBand {
                                                    if selectedBand.id! == band.id! {
                                                        self.selectedBand = nil
                                                    }
                                                } else {
                                                    self.selectedBand = band
                                                    self.selectedUser = nil
                                                    self.selectedUsers = []
                                                }
                                            } label: {
                                                HStack {
                                                    Text(band.name)
                                                        .font(.body.weight(.semibold))
                                                    Spacer()
                                                    if let selectedBand = selectedBand, selectedBand.id! == band.id! {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.blue)
                                                            .imageScale(.large)
                                                    } else {
                                                        Image(systemName: "circle")
                                                            .imageScale(.large)
                                                    }
                                                }
                                                .padding()
                                                .background(Material.regular)
                                                .foregroundColor(.primary)
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(.bottom)
                                }
                                if !authViewModel.users.isEmpty {
                                    ForEach(authViewModel.users.indices, id: \.self) { index in
                                        let user = authViewModel.users[index]
                                        
                                        Button {
                                            selectedUser = user
                                            selectedBand = nil
                                            
                                            if let userId = user.id {
                                                if let existingIndex = selectedUsers.firstIndex(where: { $0.id == userId && $0.username == user.username }) {
                                                    selectedUsers.remove(at: existingIndex)
                                                } else {
                                                    selectedUsers.append(UserToShare(id: userId, username: user.username, appVersion: user.currentVersion, notificationToken: user.fcmId))
                                                }
                                            }
                                        } label: {
                                            SongShareRowView(user: user, selectedUsers: $selectedUsers)
                                        }
                                    }
                                } else if recentSearches.contains(",") && firstSearch {
                                    HStack {
                                        ListHeaderView(title: NSLocalizedString("recently_searched", comment: ""))
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
                                                authViewModel.fetchUsers(username: search, filterCurrentUser: true) {}
                                            } label: {
                                                Text(search)
                                                    .font(.body.weight(.semibold))
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Material.regular)
                                                    .foregroundColor(.primary)
                                                    .clipShape(Capsule())
                                            }
                                            .contentShape(.contextMenuPreview, Capsule())
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
                            let bandDesc = bandsViewModel.bands.isEmpty ? "" : NSLocalizedString("or_choose_band", comment: "")
                            
                            if firstSearch {
                                if let song = song {
                                    return "Search for a user by their username \(bandDesc) to share \"\(song.title)\"."
                                } else if let folder = folder {
                                    return "Search for a user by their username \(bandDesc) to share \"\(folder.title)\"."
                                } else {
                                    return "Search for a user by their username \(bandDesc) to share."
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
                        return "Please connect to the internet to share \"\(song.title)\"."
                    } else if let folder = folder {
                        return "Please connect to the internet to share \"\(folder.title)\"."
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
                }
            }
            bandsViewModel.fetchBands()
        }
    }
}

#Preview {
    ShareView(isDisplayed: .constant(true), song: Song.song)
}
