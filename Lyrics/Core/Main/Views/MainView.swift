//
//  MainView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import SwiftUI
import MobileCoreServices
import BottomSheet

struct MainView: View {
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var sortViewModel = SortViewModel.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var networkManager = NetworkManager.shared
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    @AppStorage(showNewSongKey) var showNewSong = false
    @AppStorage(showNewFolderKey) var showNewFolder = false
    @AppStorage("showUpgradeSheet") var showUpgradeSheet = false
    
    @State var selectedSong: Song?
    @State var selectedUser: User?
    @State var draggedSong: Song?
    @State var draggedFolder: Folder?
    // Property allows folder to check if it should be displaying its songs or not. selectedFolder in the MainViewModel is used for external views, such as SongMoveView, SongEditView, etc..
    @State var selectedFolder: Folder?
    
    @State var joinedUsers: [User]?
    
    @State var hasFirestoreStartedListening = false
    @State var showNotificationAuthView = false
    @State var showMenu = false
    @State var showOfflineAlert = false
    @State var showDeleteSheet = false
    @State var showAddSongSheet = false
    @State var showEditSheet = false
    @State var showTagSheet = false
    @State var showShareSheet = false
    @State var showFolderSongDeleteSheet = false
    @State var showSongDeleteSheet = false
    @State var showSongEditSheet = false
    @State var showSongMoveSheet = false
    @State var showAllSongs = false
    @State var isEditingFolders = false
    @State var isEditingSongs = false
    @State var isEditingFolderSongs = false
    @State var isSongsCollapsed = false
    @State var isFoldersCollapsed = false
    @State var isSharedSongsCollapsed = false
    @State var showSongSearch = false
    @State var showFolderSearch = false
    @State var showFolderSongSearch = false
    @State var showFolderNotesView = false
    @State var showSharedSongsSearch = false
    @State var isLoadingFolderSongs = false
    @State var displayFolderSongsSheet = false
    @State var openedFolder = false
    @State var showSortSheet = false
    @State var isJoinedUsersLoading = false
    @State var showUserPopover = false
    @State var showCollapsedNavBar = true
    @State var showCollapsedNavBarTitle = false
    @State var showCollapsedNavBarDivider = false
    @State var showShareInvitesShadow = false
    @State var isUpdatingSharedSongs = false
    
    @State var folderSearchText = ""
    @State var songSearchText = ""
    @State var folderSongSearchText = ""
    @State var sharedSongSearchText = ""
    @State var newFolder = ""
    
    @State var sortSelection: SortSelectionEnum = .noSelection
    
    @FocusState var isFolderSongSearchFocused: Bool
    @FocusState var isFolderSearchFocused: Bool
    @FocusState var isSongSearchFocused: Bool
    
    var searchableFolders: [Folder] {
        let folders = mainViewModel.sharedFolders + mainViewModel.folders
        if folderSearchText.isEmpty {
            return folders
        } else {
            let lowercasedQuery = folderSearchText.lowercased()
            return folders.filter ({
                $0.title.lowercased().contains(lowercasedQuery)
            })
        }
    }
    var searchableSongs: [Song] {
        let lowercasedQuery = songSearchText.lowercased()
        let songs = mainViewModel.sharedSongs + mainViewModel.songs
        
        return songs
            .sorted(by: { (song1, song2) -> Bool in
                switch sortSelection {
                case .noSelection:
                    return false
                case .name:
                    return song1.title.lowercased() < song2.title.lowercased()
                case .artist:
                    return (song1.artist ?? "").lowercased() < (song2.artist ?? "").lowercased()
                case .key:
                    if let key1 = song1.key, let key2 = song2.key {
                        return key1 < key2
                    } else if song1.key != nil {
                        return true
                    } else {
                        return false
                    }
                case .dateCreated:
                    return song1.timestamp < song2.timestamp
                case .tags:
                    let tags1Exist = song1.tags != nil && !song1.tags!.isEmpty
                    let tags2Exist = song2.tags != nil && !song2.tags!.isEmpty
                    
                    if tags1Exist && !tags2Exist {
                        return true
                    } else if !tags1Exist && tags2Exist {
                        return false
                    } else if tags1Exist && tags2Exist {
                        let tags1Colors = Set(song1.tags!.map { $0.lowercased() })
                        let tags2Colors = Set(song2.tags!.map { $0.lowercased() })
                        let colorOrder: [String] = ["red", "blue", "green", "yellow", "orange"]
                        
                        let firstColor1 = colorOrder.first { tags1Colors.contains($0) }
                        let firstColor2 = colorOrder.first { tags2Colors.contains($0) }
                        
                        if let index1 = firstColor1, let index2 = firstColor2 {
                            return colorOrder.firstIndex(of: index1)! < colorOrder.firstIndex(of: index2)!
                        } else {
                            return tags1Colors.count < tags2Colors.count
                        }
                    } else {
                        return false
                    }
                }
            })
            .sorted(by: { song1, song2 in
                return (song1.pinned ?? false) && !(song2.pinned ?? false)
            })
            .filter { item in
                if !songSearchText.isEmpty {
                    if let artist = item.artist {
                        return item.title.lowercased().contains(lowercasedQuery) || artist.lowercased().contains(lowercasedQuery)
                    } else {
                        return item.title.lowercased().contains(lowercasedQuery)
                    }
                } else {
                    return true
                }
            }
    }
    func searchableFolderSongs(_ songs: [Song]) -> [Song] {
        let lowercasedQuery = songSearchText.lowercased()
        
        return songs.filter { item in
            if !folderSongSearchText.isEmpty {
                if let artist = item.artist {
                    return item.title.lowercased().contains(lowercasedQuery) || artist.lowercased().contains(lowercasedQuery)
                } else {
                    return item.title.lowercased().contains(lowercasedQuery)
                }
            } else {
                return true
            }
        }
    }
    
    let pasteboard = UIPasteboard.general
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    func sortedSongs(songs: [Song]) -> [Song] {
        return songs.sorted(by: { (song1, song2) -> Bool in
            return song1.pinned ?? false && !(song2.pinned ?? false)
        })
    }
    // We need to find a place to put this
    enum SearchArea {
        case song
        case folderSong
        case folder
    }
    
    func clearSearch(for search: SearchArea) {
        if search == .song {
            self.songSearchText = ""
            self.showSongSearch = false
            self.isSongSearchFocused = false
        }
        if search == .folderSong {
            self.folderSongSearchText = ""
            self.isFolderSongSearchFocused = false
            self.showFolderSongSearch = false
        }
        if search == .folder {
            self.folderSearchText = ""
            self.showFolderSearch = false
            self.isFolderSearchFocused = false
        }
    }
    func openFolder(_ folder: Folder) {
        self.clearSearch(for: .folderSong)
        
        self.openedFolder = true
        self.selectedFolder = folder
        self.mainViewModel.folderSongs = []
        self.mainViewModel.selectedFolder = folder
        self.mainViewModel.fetchSongs(folder)
        self.isLoadingFolderSongs = true
        
        self.fetchJoinedUsers(folder: folder) { users in
            self.joinedUsers = users
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.bouncy) {
                isLoadingFolderSongs = false
            }
        }
    }
    func closeFolder() {
        withAnimation(.bouncy) {
            self.clearSearch(for: .folderSong)
            
            self.openedFolder = false
            self.selectedFolder = nil
            self.mainViewModel.selectedFolder = nil
            self.isLoadingFolderSongs = false
        }
    }
    func fetchJoinedUsers(folder: Folder, completion: @escaping([User]) -> Void) {
        var joinedUsersStrings = folder.joinedUsers ?? []
        var users = [User]()
        let group = DispatchGroup()
        
        if uid() != folder.uid ?? "" {
            joinedUsersStrings.insert(folder.uid ?? "", at: 0)
        }
        if joinedUsersStrings.contains(uid()) {
            if let index = joinedUsersStrings.firstIndex(where: { $0 == uid() }) {
                joinedUsersStrings.remove(at: index)
            }
        }
        
        group.enter()
        authViewModel.fetchUsers(uids: joinedUsersStrings) { fetchedUsers in
            users = fetchedUsers
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(users)
            self.isJoinedUsersLoading = false
        }
    }
    func checkToFetchSharedSongs() {
        if let selectedSong = selectedSong, selectedSong.uid != uid() {
            isUpdatingSharedSongs = true
            mainViewModel.fetchSharedSongs {
                isUpdatingSharedSongs = false
            }
        }
    }
    func songContextMenu(song: Song) -> some View {
        return VStack {
            if !(song.readOnly ?? false) {
                Button {
                    selectedSong = song
                    showSongEditSheet.toggle()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            if !songViewModel.isShared(song: song) {
                Button {
                    selectedSong = song
                    showShareSheet.toggle()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            Button {
                selectedSong = song
                showSongMoveSheet.toggle()
            } label: {
                Label("Move", systemImage: "folder")
            }
            Menu {
                Button {
                    selectedSong = song
                    
                    if let title = selectedSong?.title {
                        self.pasteboard.string = title
                    }
                } label: {
                    Label("Copy Title", systemImage: "textformat")
                }
                Button {
                    selectedSong = song
                    
                    if let lyrics = selectedSong?.lyrics {
                        self.pasteboard.string = lyrics
                    }
                } label: {
                    Label("Copy Lyrics", systemImage: "doc.plaintext")
                }
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button {
                DispatchQueue.main.async {
                    if song.pinned ?? false {
                        songViewModel.unpinSong(song)
                    } else {
                        songViewModel.pinSong(song)
                    }
                }
            } label: {
                if song.pinned ?? false {
                    Label("Unpin", systemImage: "pin.slash")
                } else {
                    Label("Pin", systemImage: "pin")
                }
            }
            if !(song.readOnly ?? false) {
                Button {
                    selectedSong = song
                    showTagSheet = true
                } label: {
                    Label("Tags", systemImage: "tag")
                }
            }
            Button(role: .destructive, action: {
                selectedSong = song
                showSongDeleteSheet.toggle()
            }, label: {
                if songViewModel.isShared(song: song) {
                    Label("Leave", systemImage: "arrow.backward.square")
                } else {
                    Label("Delete", systemImage: "trash")
                }
            })
        }
    }
    
    var body: some View {
        NavigationView {
            content
                .onAppear {
                    DispatchQueue.main.async {
                        // Only allow fetches to occur once
                        if !hasFirestoreStartedListening {
                            self.mainViewModel.fetchSongs()
                            self.mainViewModel.fetchFolders()
                            self.mainViewModel.fetchSharedSongs() {}
                            self.mainViewModel.fetchSharedFolders()
                            self.mainViewModel.fetchInvites()
                            self.mainViewModel.fetchNotificationStatus()
                            self.hasFirestoreStartedListening = true
                        }
                    }
                    // Show alert instead of displaying badge on bottom edge of the display when the device is not in portrait mode to save space
                    if !NetworkManager.shared.getNetworkState() && UIDeviceOrientation.portrait.isLandscape && !mainViewModel.hasShownOfflineAlert {
                        showOfflineAlert = true
                        mainViewModel.hasShownOfflineAlert = true
                    }
                    // Check if we should show notification auth prompt
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        switch settings.authorizationStatus {
                        case .notDetermined:
                            showNotificationAuthView = true
                        case .denied:
                            DispatchQueue.main.async {
                                mainViewModel.notification = Notification(title: NSLocalizedString("dont_miss_anything_important", comment: ""), body: NSLocalizedString("stay_in_loop_enable_notifications", comment: ""), imageName: "bell-ring", type: .notificationPrompt)
                            }
                        case .authorized, .provisional, .ephemeral:
                            if let notif = mainViewModel.notification, notif.type == .notificationPrompt {
                                mainViewModel.notification = nil
                            }
                        @unknown default:
                            showNotificationAuthView = true
                        }
                    }
                    // Load user-set sort settings
                    sortViewModel.loadFromUserDefaults { sortSelection in
                        self.sortSelection = sortSelection
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var content: some View {
        VStack(spacing: 0) {
            CustomNavBar(title: NSLocalizedString("home", comment: ""), navType: .home, showBackButton: false, collapsed: $showCollapsedNavBar, collapsedTitle: $showCollapsedNavBarTitle)
                .padding()
            Divider() // TODO: fix divider showing before scroll on some devices
                .opacity(showCollapsedNavBarDivider ? 1 : 0)
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    Group {
                        AdBannerView(unitId: "ca-app-pub-5671219068273297/1814470464", height: 80, paddingTop: 16, paddingLeft: 16, paddingBottom: 0, paddingRight: 16)
                        VStack(spacing: 22) {
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ScrollViewOffsetPreferenceKey.self, value: [geo.frame(in: .global).minY])
                            }
                            .frame(height: 0)
                            VStack(alignment: .leading) {
                                Text(greeting(withName: true))
                                    .font(.largeTitle.weight(.bold))
                                HeaderActionsView([
                                    .init(title: NSLocalizedString("New Song", comment: ""), icon: "pen-to-square", scheme: .primary, action: {
                                        showNewSong = true
                                    }),
                                    .init(title: NSLocalizedString("New Folder", comment: ""), icon: "folder-plus", scheme: .primary, action: {
                                        showNewFolder = true
                                    })
                                ])
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, -18)
                            // We use a Notification object because we can use this for more than just a notification auth prompt
                            if let notif = mainViewModel.notification {
                                Button {
                                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                    
                                    UIApplication.shared.open(url)
                                } label: {
                                    HStack(spacing: 13) {
                                        FAText(iconName: "bell-ring", size: 26)
                                            .foregroundStyle(.red)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(notif.title)
                                                .font(.system(size: 18).weight(.bold))
                                                .foregroundStyle(Color.primary)
                                            Text(notif.body)
                                                .font(.system(size: 14.5))
                                                .foregroundStyle(Color.primary.opacity(0.7)) // Slight secondary gray
                                        }
                                        .multilineTextAlignment(.leading)
                                    }
                                    .padding()
                                    .padding(.horizontal, 2)
                                    .background(Material.regular)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                            }
                            VStack {
                                LazyVGrid(columns: columns) {
                                    NavigationLink(destination: {
                                        RecentlyDeletedView()
                                    }) {
                                        ContentRowView(NSLocalizedString("recently_deleted", comment: ""), icon: "trash-can", color: .red)
                                    }
                                    NavigationLink(destination: SongShareDetailView(), isActive: $mainViewModel.showShareInvites, label: {
                                        ZStack {
                                            ContentRowView(NSLocalizedString("share_invites", comment: ""), icon: "users", color: .blue)
                                                .customShadow(color: showShareInvitesShadow ? .blue.opacity(0.8) : .clear, radius: 20, x: 6, y: 6)
                                                .onChange(of: mainViewModel.incomingShareRequests.count >= 1) { _ in
                                                    withAnimation(.easeInOut) {
                                                        showShareInvitesShadow = mainViewModel.incomingShareRequests.count >= 1
                                                    }
                                                }
                                            // Badge to show number of incoming share requests
                                            HStack {
                                                Spacer()
                                                if !mainViewModel.incomingShareRequests.isEmpty {
                                                    Circle()
                                                        .frame(width: 24, height: 24)
                                                        .foregroundColor(.blue)
                                                        .overlay {
                                                            Text(String(mainViewModel.incomingShareRequests.count))
                                                                .font(.caption.weight(.semibold))
                                                                .foregroundColor(.white)
                                                        }
                                                        .offset(x: 24, y: -38)
                                                }
                                            }
                                            .padding()
                                        }
                                    })
                                    NavigationLink(destination: {
                                        BandsView()
                                    }) {
                                        ContentRowView(NSLocalizedString("bands", comment: ""), icon: "guitar", color: .blue)
                                    }
                                    NavigationLink(destination: {
                                        if let user = authViewModel.currentUser, user.hasPro ?? false {
                                            ExploreView()
                                        } else {
                                            UpgradeView()
                                        }
                                    }) {
                                        ContentRowView(NSLocalizedString("find_songs", comment: ""), icon: "magnifying-glass", color: .gray)
                                    }
                                }
                            }
                            VStack {
                                VStack {
                                    HStack {
                                        ListHeaderView(title: NSLocalizedString("folders", comment: ""))
                                        Spacer()
                                        Button {
                                            withAnimation(.bouncy) {
                                                clearSearch(for: .folder)
                                                
                                                showFolderSearch.toggle()
                                                
                                                isFoldersCollapsed = false
                                            }
                                        } label: {
                                            Image(systemName: showFolderSearch ? "xmark" : "magnifyingglass")
                                                .padding(12)
                                                .foregroundColor(Color.white)
                                                .background(Color.blue)
                                                .clipShape(Circle())
                                                .font(.footnote.weight(.bold))
                                        }
                                        Button {
                                            withAnimation(.bouncy) {
                                                clearSearch(for: .folder)
                                                
                                                isFoldersCollapsed.toggle()
                                            }
                                        } label: {
                                            Image(systemName: "chevron.down")
                                                .padding(13.5)
                                                .foregroundColor(Color.blue)
                                                .background(Material.regular)
                                                .clipShape(Circle())
                                                .font(.system(size: 18).weight(.medium))
                                        }
                                        .rotationEffect(Angle(degrees: isFoldersCollapsed ? 90 : 0))
                                    }
                                    if showFolderSearch {
                                        CustomSearchBar(text: $folderSearchText, placeholder: NSLocalizedString("search", comment: ""))
                                            .focused($isFolderSearchFocused)
                                            .onAppear {
                                                isFolderSearchFocused = true
                                            }
                                            .padding(.bottom)
                                    }
                                }
                                // TODO: conform folders to grid with a separate detail view
                                if mainViewModel.isLoadingFolders || mainViewModel.isLoadingSharedFolders {
                                    LoadingView()
                                } else {
                                    if !isFoldersCollapsed {
                                        if searchableFolders.isEmpty {
                                            EmptyStateView(state: .folders)
                                        } else {
                                            ForEach(searchableFolders) { folder  in
                                                VStack {
                                                    HStack {
                                                        Button {
                                                            if openedFolder {
                                                                if selectedFolder?.id == folder.id {
                                                                    closeFolder()
                                                                } else {
                                                                    closeFolder()
                                                                    openFolder(folder)
                                                                }
                                                            } else {
                                                                openFolder(folder)
                                                            }
                                                        } label: {
                                                            HStack {
                                                                FAText(iconName: "folder-closed", size: 18)
                                                                HStack(spacing: 7) {
                                                                    Text(folder.title)
                                                                        .lineLimit(1)
                                                                        .multilineTextAlignment(.leading)
                                                                    if folder.uid != uid() {
                                                                        Image(systemName: "person.2")
                                                                            .font(.system(size: 16).weight(.medium))
                                                                    }
                                                                }
                                                                Spacer()
                                                                if selectedFolder?.id == folder.id {
                                                                    if isLoadingFolderSongs || mainViewModel.folderSongs.isEmpty {
                                                                        ProgressView()
                                                                    } else {
                                                                        Image(systemName: "chevron.right")
                                                                            .foregroundColor(.gray)
                                                                            .rotationEffect(Angle(degrees: !isLoadingFolderSongs && selectedFolder?.id == folder.id ? 90 : 0))
                                                                    }
                                                                } else {
                                                                    Image(systemName: "chevron.right")
                                                                        .foregroundColor(.gray)
                                                                }
                                                            }
                                                            .padding()
                                                            .background(Material.regular)
                                                            .foregroundColor(.primary)
                                                            .clipShape(Capsule())
                                                            .contentShape(.contextMenuPreview, Capsule())
                                                            .contextMenu {
                                                                if folder.uid ?? "" == uid() {
                                                                    Button {
                                                                        mainViewModel.fetchSongs(folder)
                                                                        mainViewModel.selectedFolder = folder
                                                                        showAddSongSheet = true
                                                                    } label: {
                                                                        Label("Add Songs", systemImage: "plus")
                                                                    }
                                                                    Button {
                                                                        selectedSong = nil
                                                                        mainViewModel.selectedFolder = folder
                                                                        showShareSheet.toggle()
                                                                    } label: {
                                                                        Label("Share", systemImage: "square.and.arrow.up")
                                                                    }
                                                                }
                                                                if !(folder.readOnly ?? false) {
                                                                    Button {
                                                                        showEditSheet = true
                                                                        mainViewModel.selectedFolder = folder
                                                                    } label: {
                                                                        Label("Edit", systemImage: "pencil")
                                                                    }
                                                                }
                                                                Button(role: .destructive) {
                                                                    showDeleteSheet = true
                                                                    mainViewModel.selectedFolder = folder
                                                                } label: {
                                                                    // If folder does not in fact have uid, it was created with an older version of the app, and is part of the user's library, so if uid is not found, assume it is the current user's
                                                                    if folder.uid ?? uid() != uid() {
                                                                        Label("Leave", systemImage: "arrow.backward.square")
                                                                    } else {
                                                                        Label("Delete", systemImage: "trash")
                                                                    }
                                                                }
                                                            }
                                                            .onDrag {
                                                                self.draggedFolder = folder
                                                                return NSItemProvider()
                                                            }
                                                            .onDrop(
                                                                of: [.text],
                                                                delegate: FolderDropViewDelegate(
                                                                    destinationItem: folder,
                                                                    items: $mainViewModel.folders,
                                                                    draggedItem: $draggedFolder
                                                                )
                                                            )
                                                        }
                                                        .disabled(isEditingFolders)
                                                        .confirmationDialog(mainViewModel.selectedFolder?.uid ?? "" == uid() ? "Delete Folder" : "Leave Folder", isPresented: $showDeleteSheet) {
                                                            if let selectedFolder = mainViewModel.selectedFolder {
                                                                Button(selectedFolder.uid ?? "" == uid() ? "Delete" : "Leave", role: .destructive) {
                                                                    if selectedFolder.uid ?? "" == uid() {
                                                                        mainViewModel.deleteFolder(selectedFolder)
                                                                    } else {
                                                                        mainViewModel.leaveCollabFolder(folder: selectedFolder)
                                                                    }
                                                                    mainViewModel.fetchFolders()
                                                                }
                                                                Button("Cancel", role: .cancel) { }
                                                            }
                                                        } message: {
                                                            if let selectedFolder = mainViewModel.selectedFolder {
                                                                if selectedFolder.uid ?? "" == uid() {
                                                                    Text("Are you sure you want to permanently delete \"\(selectedFolder.title)\"? WARNING: This action cannot be undone!")
                                                                } else {
                                                                    Text("Are you sure you want to leave the shared folder \"\(selectedFolder.title)\"?")
                                                                }
                                                            }
                                                        }
                                                        if isEditingFolders {
                                                            Button {
                                                                showEditSheet = true
                                                                mainViewModel.selectedFolder = folder
                                                            } label: {
                                                                ListIconButtonView(imageName: "pencil", color: .blue)
                                                            }
                                                            Button {
                                                                showDeleteSheet = true
                                                                mainViewModel.selectedFolder = folder
                                                            } label: {
                                                                ListIconButtonView(imageName: "trash", color: .red)
                                                            }
                                                        }
                                                    }
                                                    if !isLoadingFolderSongs && selectedFolder?.id == folder.id && !isEditingFolders && !showEditSheet && !mainViewModel.folderSongs.isEmpty {
                                                        VStack {
                                                            if mainViewModel.folderSongs.isEmpty {
                                                                LoadingView()
                                                            } else {
                                                                HStack(spacing: 6) {
                                                                    if showFolderSongSearch {
                                                                        CustomSearchBar(text: $folderSongSearchText, placeholder: "Search")
                                                                            .focused($isFolderSongSearchFocused)
                                                                            .onAppear {
                                                                                isFolderSongSearchFocused = true
                                                                            }
                                                                    } else {
                                                                        Button {
                                                                            withAnimation(.smooth) {
                                                                                showFolderSongSearch = true
                                                                            }
                                                                        } label: {
                                                                            HStack(spacing: 6) {
                                                                                Image(systemName: "magnifyingglass")
                                                                                Text("Search")
                                                                            }
                                                                            .frame(maxWidth: .infinity)
                                                                            .font(.body.weight(.medium))
                                                                            .padding(12)
                                                                            .background(Color.blue)
                                                                            .foregroundStyle(.white)
                                                                            .clipShape(Capsule())
                                                                        }
                                                                    }
                                                                    if showFolderSongSearch {
                                                                        CloseButton {
                                                                            withAnimation(.smooth) {
                                                                                showFolderSongSearch = false
                                                                            }
                                                                        }
                                                                    } else {
                                                                        Button {
                                                                            showFolderNotesView = true
                                                                        } label: {
                                                                            HStack(spacing: 6) {
                                                                                FAText(iconName: "book", size: 18)
                                                                                Text("Notes")
                                                                            }
                                                                            .frame(maxWidth: .infinity)
                                                                            .padding(12)
                                                                            .foregroundStyle(.white)
                                                                            .background(Material.regular)
                                                                            .clipShape(Capsule())
                                                                        }
                                                                    }
                                                                }
                                                                .padding(.vertical, 10)
                                                                if !((joinedUsers ?? []).isEmpty) && !showFolderSongSearch {
                                                                    VStack(alignment: .leading, spacing: 2) {
                                                                        Text("SHARED WITH")
                                                                            .font(.caption.weight(.semibold))
                                                                        if !isJoinedUsersLoading {
                                                                            ScrollView(.horizontal) {
                                                                                HStack(spacing: 6) {
                                                                                    ForEach(self.joinedUsers ?? []) { user in
                                                                                        Button {
                                                                                            selectedUser = user
                                                                                            mainViewModel.selectedFolder = folder
                                                                                            showUserPopover = true
                                                                                        } label: {
                                                                                            UserPopoverRowView(user: user, folder: folder)
                                                                                        }
                                                                                    }
                                                                                }
                                                                                .padding(12)
                                                                                .padding(.leading)
                                                                            }
                                                                            .padding(.horizontal, -32)
                                                                        } else {
                                                                            HStack(spacing: 7) {
                                                                                ProgressView()
                                                                                Text("Loading")
                                                                                    .foregroundColor(.gray)
                                                                            }
                                                                            .padding([.horizontal, .bottom], 12)
                                                                        }
                                                                    }
                                                                }
                                                                ForEach(searchableFolderSongs(sortedSongs(songs: mainViewModel.folderSongs)), id: \.id) { uneditedSong in
                                                                    let song = {
                                                                        var song = uneditedSong
                                                                        song.readOnly = folder.readOnly
                                                                        return song
                                                                    }()
                                                                    let isShared: Bool = {
                                                                        return mainViewModel.selectedFolder?.uid ?? uid() != uid()
                                                                    }()
                                                                    
                                                                    if song.title == "noSongs" {
                                                                        Text("No Songs")
                                                                            .foregroundColor(Color.gray)
                                                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                                            .deleteDisabled(true)
                                                                            .moveDisabled(true)
                                                                    } else {
                                                                        NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.folderSongs, folder: folder, joinedUsers: joinedUsers, isSongFromFolder: true)) {
                                                                            ListRowView(title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "thumbtack" : "", song: song)
                                                                                .contextMenu {
                                                                                    if !(song.readOnly ?? false) {
                                                                                        Button {
                                                                                            selectedSong = song
                                                                                            songViewModel.fetchSong(selectedSong?.id ?? "") { song in
                                                                                                selectedSong = song
                                                                                            } regCompletion: { _ in }
                                                                                            showSongEditSheet.toggle()
                                                                                        } label: {
                                                                                            Label("Edit", systemImage: "pencil")
                                                                                        }
                                                                                    }
                                                                                    if !isShared {
                                                                                        Button {
                                                                                            selectedSong = song
                                                                                            showShareSheet.toggle()
                                                                                        } label: {
                                                                                            Label("Share", systemImage: "square.and.arrow.up")
                                                                                        }
                                                                                    }
                                                                                    if !songViewModel.isShared(song: song) && folder.uid ?? "" == uid() {
                                                                                        Button {
                                                                                            selectedSong = song
                                                                                            showSongMoveSheet.toggle()
                                                                                        } label: {
                                                                                            Label("Move", systemImage: "folder")
                                                                                        }
                                                                                    }
                                                                                    Menu {
                                                                                        Button {
                                                                                            selectedSong = song
                                                                                            let pasteboard = UIPasteboard.general
                                                                                            pasteboard.string = selectedSong?.title
                                                                                        } label: {
                                                                                            Label("Copy Title", systemImage: "textformat")
                                                                                        }
                                                                                        Button {
                                                                                            selectedSong = song
                                                                                            let pasteboard = UIPasteboard.general
                                                                                            pasteboard.string = selectedSong?.lyrics
                                                                                        } label: {
                                                                                            Label("Copy Lyrics", systemImage: "doc.plaintext")
                                                                                        }
                                                                                    } label: {
                                                                                        Label("Copy", systemImage: "doc.on.doc")
                                                                                    }
                                                                                    if song.uid == uid() {
                                                                                        Button {
                                                                                            mainViewModel.selectedFolder = folder
                                                                                            selectedSong = song
                                                                                            showTagSheet = true
                                                                                        } label: {
                                                                                            Label("Tags", systemImage: "tag")
                                                                                        }
                                                                                    }
                                                                                    if folder.uid ?? "" == uid() {
                                                                                        Button {
                                                                                            if song.pinned ?? false {
                                                                                                songViewModel.unpinSong(song)
                                                                                            } else {
                                                                                                songViewModel.pinSong(song)
                                                                                            }
                                                                                            mainViewModel.fetchSongs(folder)
                                                                                        } label: {
                                                                                            if song.pinned ?? false {
                                                                                                Label("Unpin", systemImage: "pin.slash")
                                                                                            } else {
                                                                                                Label("Pin", systemImage: "pin")
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                    Button(role: .destructive) {
                                                                                        selectedSong = song
                                                                                        mainViewModel.selectedFolder = folder
                                                                                        showFolderSongDeleteSheet.toggle()
                                                                                    } label: {
                                                                                        Label("Remove", systemImage: "trash")
                                                                                    }
                                                                                }
                                                                                .confirmationDialog(isShared ? "Remove Song" : "Delete Song", isPresented: $showFolderSongDeleteSheet) {
                                                                                    if let selectedSong = selectedSong {
                                                                                        if !isShared {
                                                                                            Button("Delete", role: .destructive) {
                                                                                                songViewModel.moveSongToRecentlyDeleted(selectedSong)
                                                                                            }
                                                                                        }
                                                                                        Button("Remove from Folder") {
                                                                                            mainViewModel.deleteSong(folder, selectedSong)
                                                                                        }
                                                                                        Button("Cancel", role: .cancel) {}
                                                                                    }
                                                                                } message: {
                                                                                    if let selectedSong = selectedSong {
                                                                                        Text("Are you sure you want to \(isShared ? "remove" : "delete") \"\(selectedSong.title)\"?")
                                                                                    }
                                                                                }
                                                                        }
                                                                        .onDrag {
                                                                            self.draggedSong = song
                                                                            return NSItemProvider()
                                                                        }
                                                                        .onDrop(
                                                                            of: [.text],
                                                                            delegate: FolderSongDropViewDelegate(
                                                                                folder: folder,
                                                                                destinationItem: song,
                                                                                items: $mainViewModel.folderSongs,
                                                                                draggedItem: $draggedSong
                                                                            )
                                                                        )
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        .padding(.leading)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .id("folders")
                            VStack {
                                VStack {
                                    HStack(spacing: 3) {
                                        ListHeaderView(title: NSLocalizedString("my_songs", comment: ""))
                                        Spacer()
                                        Button {
                                            withAnimation(.bouncy) {
                                                clearSearch(for: .song)
                                                
                                                showSongSearch.toggle()
                                                
                                                isSongsCollapsed = false
                                            }
                                        } label: {
                                            Image(systemName: showSongSearch ? "xmark" : "magnifyingglass")
                                                .padding(12)
                                                .foregroundColor(Color.white)
                                                .background(Color.blue)
                                                .clipShape(Circle())
                                                .font(.footnote.weight(.bold))
                                        }
                                        if mainViewModel.songs.filter({ song in
                                            if song.title != "noSongs" {
                                                return false
                                            }
                                            return true
                                        }).count < 1 {
                                            Button {
                                                showSortSheet.toggle()
                                            } label: {
                                                if sortSelection == .noSelection {
                                                    Image(systemName: "line.3.horizontal.decrease")
                                                        .padding(12)
                                                        .foregroundColor(Color.blue)
                                                        .background(Material.regular)
                                                        .clipShape(Circle())
                                                        .font(.system(size: 18).weight(.bold))
                                                } else {
                                                    Image(systemName: "line.3.horizontal.decrease")
                                                        .padding(12)
                                                        .foregroundColor(Color.white)
                                                        .background(Color.blue)
                                                        .clipShape(Circle())
                                                        .font(.system(size: 18).weight(.bold))
                                                }
                                            }
                                            .bottomSheet(isPresented: $showSortSheet, detents: [.medium()]) {
                                                SortView(isPresented: $showSortSheet, sortSelection: $sortSelection)
                                            }
                                        }
                                        Button {
                                            withAnimation(.bouncy) {
                                                clearSearch(for: .song)
                                                
                                                isSongsCollapsed.toggle()
                                            }
                                        } label: {
                                            Image(systemName: "chevron.down")
                                                .padding(13.5)
                                                .foregroundColor(Color.blue)
                                                .background(Material.regular)
                                                .clipShape(Circle())
                                                .font(.system(size: 18).weight(.medium))
                                        }
                                        .rotationEffect(Angle(degrees: isSongsCollapsed ? 90 : 0))
                                    }
                                    if showSongSearch {
                                        CustomSearchBar(text: $songSearchText, placeholder: NSLocalizedString("search", comment: ""))
                                            .padding(.bottom)
                                            .focused($isSongSearchFocused)
                                            .onAppear {
                                                isSongSearchFocused = true
                                            }
                                    }
                                }
                                if !isSongsCollapsed {
                                    if mainViewModel.isLoadingSongs || (mainViewModel.isLoadingSharedSongs && !isUpdatingSharedSongs) {
                                        LoadingView()
                                    } else {
                                        if searchableSongs.isEmpty {
                                            EmptyStateView(state: .songs)
                                                .moveDisabled(true)
                                        } else {
                                            ForEach(searchableSongs) { song in
                                                HStack {
                                                    NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.songs)) {
                                                        ListRowView(title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "thumbtack" : "", song: song)
                                                            .contextMenu {
                                                                songContextMenu(song: song)
                                                            }
                                                            .confirmationDialog("\(selectedSong?.id ?? "" == uid() ? "Delete" : "Leave") Song", isPresented: $showSongDeleteSheet) {
                                                                if let selectedSong = selectedSong {
                                                                    Button(songViewModel.isShared(song: selectedSong) ? "Leave" : "Delete", role: .destructive) {
                                                                        if songViewModel.isShared(song: selectedSong) {
                                                                            songViewModel.leaveSong(song: selectedSong)
                                                                        } else {
                                                                            songViewModel.moveSongToRecentlyDeleted(selectedSong)
                                                                        }
                                                                    }
                                                                    Button("Cancel", role: .cancel) {}
                                                                }
                                                            } message: {
                                                                if let selectedSong = selectedSong {
                                                                    Text("Are you sure you want to \(songViewModel.isShared(song: selectedSong) ? "leave" : "delete") \"\(selectedSong.title)\"?")
                                                                }
                                                            }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .id("songs")
                    }
                    .padding()
                    .padding(.bottom, !NetworkManager.shared.getNetworkState() || mainViewModel.updateAvailable ? 75 : 0)
                    .bottomSheet(isPresented: $showUserPopover, detents: [.medium()]) {
                        UserPopover(joinedUsers: $joinedUsers, selectedUser: $selectedUser, song: nil, folder: mainViewModel.selectedFolder, isSongFromFolder: true)
                    }
                    .fullScreenCover(isPresented: $showUpgradeSheet) {
                        UpgradeView()
                    }
                    .fullScreenCover(isPresented: $showNotificationAuthView) {
                        NotificationAuthView()
                    }
                    .sheet(isPresented: $showFolderNotesView) {
                        NotesView(folder: selectedFolder)
                    }
                    .sheet(isPresented: $showEditSheet) {
                        if let selectedFolder = mainViewModel.selectedFolder {
                            FolderEditView(folder: selectedFolder, isDisplayed: $showEditSheet, title: .constant(selectedFolder.title))
                        }
                    }
                    .sheet(isPresented: $showShareSheet) {
                        if let song = selectedSong {
                            ShareView(isDisplayed: $showShareSheet, song: song)
                        }  else if let folder = mainViewModel.selectedFolder {
                            ShareView(isDisplayed: $showShareSheet, folder: folder)
                        }
                    }
                    .sheet(isPresented: $showAddSongSheet, onDismiss: {mainViewModel.fetchSongs(mainViewModel.selectedFolder!)}) {
                        if let selectedFolder = mainViewModel.selectedFolder {
                            AddSongsView(folder: selectedFolder)
                        }
                    }
                    .sheet(isPresented: $showSongMoveSheet) {
                        if let selectedSong = selectedSong {
                            SongMoveView(song: selectedSong, showProfileView: $showSongMoveSheet, songTitle: selectedSong.title)
                        }
                    }
                    .sheet(isPresented: $showSongEditSheet, onDismiss: checkToFetchSharedSongs) {
                        if let selectedSong = selectedSong {
                            SongEditView(song: selectedSong, isDisplayed: $showEditSheet, title: .constant(selectedSong.title), key: .constant(selectedSong.key ?? NSLocalizedString("not_set", comment: "")), artist: .constant(selectedSong.artist ?? ""), duration: .constant(selectedSong.duration ?? ""))
                        }
                    }
                    .sheet(isPresented: $showTagSheet, onDismiss: checkToFetchSharedSongs) {
                        if let selectedSong = selectedSong {
                            let tags: [TagSelectionEnum] = selectedSong.tags?.compactMap { TagSelectionEnum(rawValue: $0) } ?? []
                            SongTagView(isPresented: $showTagSheet, tagsToUpdate: .constant([]), tags: tags, song: selectedSong)
                        }
                    }
                    .confirmationDialog("\(selectedSong?.id ?? "" == uid() ? "Delete" : "Leave") Song", isPresented: $showSongDeleteSheet) {
                        if let selectedSong = selectedSong {
                            Button(songViewModel.isShared(song: selectedSong) ? "Leave" : "Delete", role: .destructive) {
                                if !songViewModel.isShared(song: selectedSong) {
                                    songViewModel.moveSongToRecentlyDeleted(selectedSong)
                                } else {
                                    songViewModel.leaveSong(song: selectedSong)
                                }
                            }
                        }
                    }
                    .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                        let animation = Animation.easeInOut(duration: 0.22)
                        
                        if hasHomeButton() ? value.first ?? 0 <= 100 : value.first ?? 0 <= 145 {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    showCollapsedNavBarDivider = true
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    showCollapsedNavBarDivider = false
                                }
                            }
                        }
                        if value.first ?? 0 <= 55 {
                            DispatchQueue.main.async {
                                withAnimation(animation) {
                                    showCollapsedNavBarTitle = true
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                withAnimation(animation) {
                                    showCollapsedNavBarTitle = false
                                }
                            }
                        }
                        if value.first ?? 0 <= -15 {
                            DispatchQueue.main.async {
                                withAnimation(animation) {
                                    showCollapsedNavBar = false
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                withAnimation(animation) {
                                    showCollapsedNavBar = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if !NetworkManager.shared.getNetworkState() || mainViewModel.updateAvailable {
                let notConnectedAndInPortrait = !NetworkManager.shared.getNetworkState() && UIDeviceOrientation.portrait.isPortrait
                
                VStack {
                    Spacer()
                    ZStack {
                        if notConnectedAndInPortrait {
                            VisualEffectBlur(blurStyle: .systemMaterial)
                                .mask(LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.clear]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                ))
                                .edgesIgnoringSafeArea(.all)
                        }
                        VStack {
                            Spacer()
                            if notConnectedAndInPortrait {
                                Button {
                                    showOfflineAlert = true
                                } label: {
                                    HStack(spacing: 7) {
                                        FAText(iconName: "wifi-slash", size: 18)
                                        Text(NSLocalizedString("youre_offline", comment: ""))
                                    }
                                    .padding(15)
                                    .background(Color.red.opacity(0.9))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .customShadow(color: .red, radius: 20, x: 6, y: 6)
                                    .padding()
                                }
                            } else if mainViewModel.updateAvailable {
                                Button {
                                    if let url = URL(string: "https://apps.apple.com/app/id6449195237") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 7) {
                                        FAText(iconName: "download", size: 18)
                                        Text(NSLocalizedString("update_available", comment: ""))
                                    }
                                    .padding(15)
                                    .background(Color.blue.opacity(0.9))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .customShadow(color: .blue, radius: 20, x: 6, y: 6)
                                    .padding()
                                }
                            }
                        }
                    }
                    .frame(height: 80)
                }
            }
        }
        .alert(isPresented: $showOfflineAlert) {
            Alert(title: Text("youre_offline"), message: Text("some_features_may_not_work_expectedly"), dismissButton: .cancel(Text("OK")))
        }
    }
}

#Preview {
    MainView()
}
