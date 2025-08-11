//
//  MainView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import SwiftUI
import MobileCoreServices
import BottomSheet

enum SearchTarget {
    case song
    case folderSong
    case folder
}

struct MainView: View {
    @ObservedObject private var mainViewModel = MainViewModel.shared
    @ObservedObject private var songViewModel = SongViewModel.shared
    @ObservedObject private var sortViewModel = SortViewModel.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var networkManager = NetworkManager.shared
    @ObservedObject private var authViewModel = AuthViewModel.shared
    
    @AppStorage(showNewSongKey) private var showNewSong = false
    @AppStorage(showNewFolderKey) private var showNewFolder = false
    @AppStorage("showUpgradeSheet") private var showUpgradeSheet = false
    @AppStorage("fullname") private var fullname: String?
    
    @State private var selectedSong: Song?
    @State private var selectedUser: User?
    @State private var draggedSong: Song?
    @State private var draggedFolder: Folder?
    // Property allows folder to check if it should be displaying its songs or not. selectedFolder in the MainViewModel is used for external views, such as SongMoveView, SongEditView, etc..
    @State private var selectedFolder: Folder?
    @State private var joinedUsers: [User]?
    
    @State private var hasFirestoreStartedListening = false
    @State private var showNotificationAuthView = false
    @State private var showMenu = false
    @State private var showDeleteSheet = false
    @State private var showAddSongSheet = false
    @State private var showEditSheet = false
    @State private var showTagSheet = false
    @State private var showShareSheet = false
    @State private var showFolderSongDeleteSheet = false
    @State private var showSongDeleteSheet = false
    @State private var showSongEditSheet = false
    @State private var showSongMoveSheet = false
    @State private var showAllSongs = false
    @State private var isSongsCollapsed = false
    @State private var isFoldersCollapsed = false
    @State private var isSharedSongsCollapsed = false
    @State private var showSongSearch = false
    @State private var showFolderSearch = false
    @State private var showFolderSongSearch = false
    @State private var showFolderNotesView = false
    @State private var showSharedSongsSearch = false
    @State private var isLoadingFolderSongs = false
    @State private var displayFolderSongsSheet = false
    @State private var openedFolder = false
    @State private var showSortSheet = false
    @State private var isJoinedUsersLoading = false
    @State private var showUserPopover = false
    @State private var showCollapsedNavBar = true
    @State private var showCollapsedNavBarTitle = false
    @State private var showCollapsedNavBarDivider = false
    @State private var showShareInvitesShadow = false
    @State private var isUpdatingSharedSongs = false
    
    @State private var folderSearchText = ""
    @State private var songSearchText = ""
    @State private var folderSongSearchText = ""
    @State private var sharedSongSearchText = ""
    @State private var newFolder = ""
    
    @State private var sortSelection: SortSelectionEnum = .noSelection
    
    @FocusState private var isFolderSongSearchFocused: Bool
    @FocusState private var isFolderSearchFocused: Bool
    @FocusState private var isSongSearchFocused: Bool
    
    private var searchableFolders: [Folder] {
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
    private var searchableSongs: [Song] {
        let lowercasedQuery = songSearchText.lowercased()
        let songs = mainViewModel.sharedSongs + mainViewModel.songs
        
        return songs
            .sorted(by: { (song1, song2) -> Bool in
                switch sortSelection {
                case .noSelection:
                    // Don't give any songs sort priority
                    return false
                case .name:
                    return song1.title.lowercased() < song2.title.lowercased()
                case .artist:
                    return (song1.artist ?? "").lowercased() < (song2.artist ?? "").lowercased()
                case .key:
                    if let key1 = song1.key, let key2 = song2.key {
                        // Both songs have keys, sort alphabetically
                        return key1 < key2
                    } else if song1.key != nil {
                        // The second song doesn't have a key, sort the first song above it
                        return true
                    } else {
                        // The first song doesn't have a key, don't change the order
                        return false
                    }
                case .dateCreated:
                    return song1.timestamp < song2.timestamp
                case .tags:
                    let tags1Exist = song1.tags != nil && !song1.tags!.isEmpty
                    let tags2Exist = song2.tags != nil && !song2.tags!.isEmpty
                    
                    if tags1Exist && !tags2Exist {
                        // If there are tags on the first song, sort it above the second
                        return true
                    } else if !tags1Exist && tags2Exist {
                        // If there are tags on the second song, sort it above the first
                        return false
                    } else if tags1Exist && tags2Exist {
                        // Create a set of tags and ensure they'll match the color order array by lowercasing
                        let tags1Colors = Set(song1.tags!.map { $0.lowercased() })
                        let tags2Colors = Set(song2.tags!.map { $0.lowercased() })
                        // This is the order tags will be sorted in
                        let colorOrder: [String] = ["red", "blue", "green", "yellow", "orange"]
                        
                        // Get the tag for each song
                        let firstColor1 = colorOrder.first { tags1Colors.contains($0) }
                        let firstColor2 = colorOrder.first { tags2Colors.contains($0) }
                        
                        if let index1 = firstColor1, let index2 = firstColor2 {
                            // Sort based on which tag comes first
                            return colorOrder.firstIndex(of: index1)! < colorOrder.firstIndex(of: index2)!
                        } else {
                            // Currently, there won't be more than one tag present at one time
                            // But if it is eventually supported, this will sort based on which song has more tags
                            return tags1Colors.count < tags2Colors.count
                        }
                    } else {
                        return false
                    }
                }
            })
            .filter { item in
                // When the user is searching, filter songs by title and artist
                if !songSearchText.isEmpty {
                    let titleMatch = item.title.lowercased().contains(lowercasedQuery)
                    if let artist = item.artist {
                        return titleMatch || artist.lowercased().contains(lowercasedQuery)
                    } else {
                        return titleMatch
                    }
                } else {
                    return true
                }
            }
    }
    private var isLoadingSongs: Bool {
        return mainViewModel.isLoadingSongs || (mainViewModel.isLoadingSharedSongs && !isUpdatingSharedSongs)
    }
    
    private let pasteboard = UIPasteboard.general
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private func sortedSongs(songs: [Song]) -> [Song] {
        return songs.sorted(by: { (song1, song2) -> Bool in
            let song1Pinned = song1.pinned ?? false
            let song2Pinned = song2.pinned ?? false
            
            // Additionally, move all the pinned songs to the top
            return song1Pinned && !song2Pinned
        })
    }
    private func searchableFolderSongs(_ songs: [Song]) -> [Song] {
        let lowercasedQuery = folderSongSearchText.lowercased()
        
        return songs.filter { item in
            if !folderSongSearchText.isEmpty {
                // When the user is searching, filter based on title and artist
                let titleMatch = item.title.lowercased().contains(lowercasedQuery)
                if let artist = item.artist {
                    return titleMatch || artist.lowercased().contains(lowercasedQuery)
                } else {
                    return titleMatch
                }
            } else {
                return true
            }
        }
    }
    private func clearSearch(for search: SearchTarget) {
        if search == .song {
            self.songSearchText = ""
            self.isSongSearchFocused = false
        }
        if search == .folderSong {
            self.folderSongSearchText = ""
            self.isFolderSongSearchFocused = false
            self.showFolderSongSearch = false
        }
        if search == .folder {
            self.folderSearchText = ""
            self.isFolderSearchFocused = false
        }
    }
    private func openFolder(_ folder: Folder) {
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
    private func closeFolder() {
        withAnimation(.bouncy) {
            self.clearSearch(for: .folderSong)
            
            self.openedFolder = false
            self.selectedFolder = nil
            self.mainViewModel.selectedFolder = nil
            self.isLoadingFolderSongs = false
        }
    }
    private func fetchJoinedUsers(folder: Folder, completion: @escaping([User]) -> Void) {
        var joinedUsersStrings = folder.joinedUsers ?? []
        var users = [User]()
        let group = DispatchGroup()
        
        if uid() != folder.uid ?? "" {
            // If the current user is not the owner of the folder, add the owner to the list
            joinedUsersStrings.insert(folder.uid ?? "", at: 0)
        }
        if joinedUsersStrings.contains(uid()) {
            // We never want to show the current user, so remove them if they're there
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
    private func songContextMenu(song: Song) -> some View {
        return VStack {
            if !(song.readOnly ?? false) {
                Button {
                    selectedSong = song
                    showSongEditSheet.toggle()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            if !songViewModel.isShared(song) {
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
                if song.pinned ?? false {
                    songViewModel.unpinSong(song)
                } else {
                    songViewModel.pinSong(song)
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
            Button(role: .destructive) {
                selectedSong = song
                showSongDeleteSheet.toggle()
            } label: {
                if songViewModel.isShared(song) {
                    Label("Leave", systemImage: "arrow.backward.square")
                } else {
                    Label("Delete", systemImage: "trash")
                }
            }
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
            CustomNavBar(NSLocalizedString("home", comment: ""), for: .home, showBackButton: false, collapsed: $showCollapsedNavBar, collapsedTitle: $showCollapsedNavBarTitle)
            Divider()
                .opacity(showCollapsedNavBarDivider ? 1 : 0)
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack {
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
                                                .shadow(color: showShareInvitesShadow ? .blue.opacity(0.8) : .clear, radius: 20, x: 6, y: 6)
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
//                                    NavigationLink(destination: {
//                                        BandsView()
//                                    }) {
//                                        ContentRowView(NSLocalizedString("bands", comment: ""), icon: "guitar", color: .blue)
//                                    }
                                }
                            }
                            VStack {
                                VStack {
                                    HStack {
                                        ListHeaderView(title: NSLocalizedString("folders", comment: ""))
                                        Spacer()
                                        if !showFolderSearch {
                                            Button {
                                                withAnimation(.bouncy) {
                                                    clearSearch(for: .folder)
                                                    
                                                    showFolderSearch.toggle()
                                                    
                                                    isFoldersCollapsed = false
                                                }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "magnifyingglass")
                                                    Text("Search")
                                                }
                                                .padding(12)
                                                .foregroundColor(.white)
                                                .background(Color.blue)
                                                .clipShape(Capsule())
                                                .font(.system(size: 13).weight(.semibold))
                                            }
                                        }
                                        Button {
                                            withAnimation(.bouncy) {
                                                clearSearch(for: .folder)
                                                
                                                showFolderSearch = false
                                                
                                                isFoldersCollapsed.toggle()
                                            }
                                        } label: {
                                            Image(systemName: "chevron.down")
                                                .padding(14)
                                                .foregroundColor(Color.blue)
                                                .background(Material.regular)
                                                .clipShape(Circle())
                                                .font(.system(size: 18).weight(.semibold))
                                        }
                                        .rotationEffect(Angle(degrees: isFoldersCollapsed ? 90 : 0))
                                    }
                                    if showFolderSearch {
                                        HStack(spacing: 6) {
                                            CustomSearchBar(text: $folderSearchText, placeholder: NSLocalizedString("search", comment: ""))
                                                .focused($isFolderSearchFocused)
                                                .onAppear {
                                                    isFolderSearchFocused = true
                                                }
                                            CloseButton {
                                                withAnimation(.bouncy) {
                                                    clearSearch(for: .folder)
                                                    
                                                    showFolderSearch = false
                                                }
                                            }
                                        }
                                        .padding(.bottom)
                                    }
                                }
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
                                                                if isLoadingFolderSongs && selectedFolder?.id == folder.id {
                                                                    ProgressView()
                                                                } else {
                                                                    Image(systemName: "chevron.right")
                                                                        .foregroundColor(.gray)
                                                                        .rotationEffect(Angle(degrees: !isLoadingFolderSongs && selectedFolder?.id == folder.id ? 90 : 0))
                                                                }
                                                            }
                                                            .padding()
                                                            .background(Material.regular)
                                                            .foregroundColor(.primary)
                                                            .clipShape(Capsule())
                                                            .contentShape(.contextMenuPreview, Capsule())
                                                            .contextMenu {
                                                                let readOnly = (folder.readOnly ?? false)
                                                                
                                                                if !readOnly {
                                                                    Button {
                                                                        mainViewModel.selectedFolder = folder
                                                                        showAddSongSheet = true
                                                                    } label: {
                                                                        Label("Add Songs", systemImage: "plus")
                                                                    }
                                                                }
                                                                if folder.uid ?? "" == uid() {
                                                                    Button {
                                                                        selectedSong = nil
                                                                        mainViewModel.selectedFolder = folder
                                                                        showShareSheet.toggle()
                                                                    } label: {
                                                                        Label("Share", systemImage: "square.and.arrow.up")
                                                                    }
                                                                }
                                                                Button {
                                                                    selectedSong = nil
                                                                    mainViewModel.selectedFolder = folder
                                                                    showFolderNotesView = true
                                                                } label: {
                                                                    Label("Notes", systemImage: "document")
                                                                }
                                                                if !readOnly {
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
                                                        .confirmationDialog(mainViewModel.selectedFolder?.uid ?? "" == uid() ? "Delete Folder" : "Leave Folder", isPresented: $showDeleteSheet) {
                                                            if let selectedFolder = mainViewModel.selectedFolder {
                                                                let hasOwnership = selectedFolder.uid ?? "" == uid()
                                                                
                                                                Button(hasOwnership ? "Delete" : "Leave", role: .destructive) {
                                                                    if hasOwnership {
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
                                                    }
                                                    if !isLoadingFolderSongs && selectedFolder?.id == folder.id && !showEditSheet {
                                                        VStack {
                                                            if mainViewModel.isLoadingFolderSongs {
                                                                LoadingView()
                                                            } else {
                                                                let songs = searchableFolderSongs(sortedSongs(songs: mainViewModel.folderSongs))
                                                                
                                                                HStack(spacing: 6) {
                                                                    if showFolderSongSearch {
                                                                        CustomSearchBar(text: $folderSongSearchText, placeholder: "Search")
                                                                            .focused($isFolderSongSearchFocused)
                                                                            .onAppear {
                                                                                isFolderSongSearchFocused = true
                                                                            }
                                                                    } else {
                                                                        Button {
                                                                            withAnimation(.bouncy) {
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
                                                                            withAnimation(.bouncy) {
                                                                                clearSearch(for: .folderSong)
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
                                                                if songs.isEmpty {
                                                                    EmptyStateView(state: .folderSongs)
                                                                } else {
                                                                    ForEach(songs, id: \.id) { uneditedSong in
                                                                        let song = {
                                                                            var song = uneditedSong
                                                                            song.readOnly = folder.readOnly
                                                                            return song
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
                                                                                                showSongEditSheet.toggle()
                                                                                            } label: {
                                                                                                Label("Edit", systemImage: "pencil")
                                                                                            }
                                                                                        }
                                                                                        if song.uid == uid() {
                                                                                            Button {
                                                                                                selectedSong = song
                                                                                                showShareSheet.toggle()
                                                                                            } label: {
                                                                                                Label("Share", systemImage: "square.and.arrow.up")
                                                                                            }
                                                                                        }
                                                                                        if !songViewModel.isShared(song) && folder.uid ?? "" == uid() {
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
                                                                                            showFolderSongDeleteSheet = true
                                                                                        } label: {
                                                                                            Label("Remove", systemImage: "trash")
                                                                                        }
                                                                                    }
                                                                                    .confirmationDialog(songViewModel.isShared(song) ? "Remove Song" : "Delete Song", isPresented: $showFolderSongDeleteSheet) {
                                                                                        if let selectedSong {
                                                                                            if !songViewModel.isShared(selectedSong) {
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
                                                                                        if let selectedSong {
                                                                                            Text("Are you sure you want to \(songViewModel.isShared(selectedSong) ? "remove" : "delete") \"\(selectedSong.title)\"?")
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
                                        if !showSongSearch {
                                            Button {
                                                withAnimation(.bouncy) {
                                                    clearSearch(for: .song)
                                                    
                                                    showSongSearch.toggle()
                                                    
                                                    isSongsCollapsed = false
                                                }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "magnifyingglass")
                                                    Text("Search")
                                                }
                                                .padding(12)
                                                .foregroundColor(.white)
                                                .background(Color.blue)
                                                .clipShape(Capsule())
                                                .font(.system(size: 13).weight(.semibold))
                                            }
                                        }
                                        if mainViewModel.songs.count > 1 && !isLoadingSongs {
                                            Button {
                                                showSortSheet.toggle()
                                            } label: {
                                                Image(systemName: "line.3.horizontal.decrease")
                                                    .padding(12)
                                                    .foregroundColor(sortSelection == .noSelection ? Color.blue : Color.white)
                                                    .background(sortSelection == .noSelection ? AnyShapeStyle(Material.regular) : AnyShapeStyle(Color.blue))
                                                    .clipShape(Circle())
                                                    .font(.system(size: 18).weight(.bold))
                                            }
                                            .bottomSheet(isPresented: $showSortSheet, detents: [.medium()]) {
                                                SortView(isPresented: $showSortSheet, sortSelection: $sortSelection)
                                            }
                                        }
                                        Button {
                                            withAnimation(.bouncy) {
                                                clearSearch(for: .song)
                                                
                                                showSongSearch = false
                                                
                                                isSongsCollapsed.toggle()
                                            }
                                        } label: {
                                            Image(systemName: "chevron.down")
                                                .padding(14)
                                                .foregroundColor(Color.blue)
                                                .background(Material.regular)
                                                .clipShape(Circle())
                                                .font(.system(size: 18).weight(.semibold))
                                        }
                                        .rotationEffect(Angle(degrees: isSongsCollapsed ? 90 : 0))
                                    }
                                    if showSongSearch {
                                        HStack(spacing: 6) {
                                            CustomSearchBar(text: $songSearchText, placeholder: NSLocalizedString("search", comment: ""))
                                                .focused($isSongSearchFocused)
                                                .onAppear {
                                                    isSongSearchFocused = true
                                                }
                                            CloseButton {
                                                withAnimation(.bouncy) {
                                                    clearSearch(for: .song)
                                                    
                                                    showSongSearch = false
                                                }
                                            }
                                        }
                                        .padding(.bottom)
                                    }
                                }
                                if !isSongsCollapsed {
                                    if isLoadingSongs {
                                        LoadingView()
                                    } else {
                                        if searchableSongs.isEmpty {
                                            EmptyStateView(state: .songs)
                                                .moveDisabled(true)
                                        } else {
                                            ForEach(sortedSongs(songs: searchableSongs)) { song in
                                                HStack {
                                                    NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.songs)) {
                                                        ListRowView(title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "thumbtack" : "", song: song)
                                                            .contextMenu {
                                                                songContextMenu(song: song)
                                                            }
                                                            .confirmationDialog("\(selectedSong?.id ?? "" == uid() ? "Delete" : "Leave") Song", isPresented: $showSongDeleteSheet) {
                                                                if let selectedSong = selectedSong {
                                                                    Button(songViewModel.isShared(selectedSong) ? "Leave" : "Delete", role: .destructive) {
                                                                        if songViewModel.isShared(selectedSong) {
                                                                            songViewModel.leaveSong(song: selectedSong)
                                                                        } else {
                                                                            songViewModel.moveSongToRecentlyDeleted(selectedSong)
                                                                        }
                                                                    }
                                                                    Button("Cancel", role: .cancel) {}
                                                                }
                                                            } message: {
                                                                if let selectedSong = selectedSong {
                                                                    Text("Are you sure you want to \(songViewModel.isShared(selectedSong) ? "leave" : "delete") \"\(selectedSong.title)\"?")
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
                        AlertView(AlertViewAlert(title: NSLocalizedString("Do you want to allow notifications?", comment: ""), subtitle: NSLocalizedString("If you enable them, you'll be able to notified when someone shares you a song, or accepts or declines a shared song from you.", comment: ""), icon: "bell-ring", accent: .red), primary: AlertButton(title: NSLocalizedString("Allow Notifications", comment: ""), action: {
                            AppDelegate().registerForNotifications {
                                showNotificationAuthView = false
                            }
                        }), secondary: AlertButton(title: NSLocalizedString("I don't want notifications", comment: ""), action: {
                            showNotificationAuthView = false
                        }))
                    }
                    .sheet(isPresented: $showFolderNotesView) {
                        NotesView(folder: mainViewModel.selectedFolder)
                    }
                    .sheet(isPresented: $showEditSheet) {
                        if let selectedFolder = mainViewModel.selectedFolder {
                            FolderEditView(folder: selectedFolder, isDisplayed: $showEditSheet, title: .constant(selectedFolder.title))
                        } else {
                            LoadingFailedView()
                        }
                    }
                    .sheet(isPresented: $showShareSheet) {
                        if let song = selectedSong {
                            ShareView(isDisplayed: $showShareSheet, song: song)
                        }  else if let folder = mainViewModel.selectedFolder {
                            ShareView(isDisplayed: $showShareSheet, folder: folder)
                        } else {
                            LoadingFailedView()
                        }
                    }
                    .sheet(isPresented: $showAddSongSheet, onDismiss: {mainViewModel.fetchSongs(mainViewModel.selectedFolder!)}) {
                        if let selectedFolder = mainViewModel.selectedFolder {
                            AddSongsView(folder: selectedFolder)
                        } else {
                            LoadingFailedView()
                        }
                    }
                    .sheet(isPresented: $showSongMoveSheet) {
                        if let selectedSong = selectedSong {
                            SongMoveView(song: selectedSong)
                        } else {
                            LoadingFailedView()
                        }
                    }
                    .sheet(isPresented: $showSongEditSheet) {
                        if let selectedSong = selectedSong {
                            SongEditView(song: selectedSong, isDisplayed: $showEditSheet, title: .constant(selectedSong.title), key: .constant(selectedSong.key ?? ""), artist: .constant(selectedSong.artist ?? ""))
                        } else {
                            LoadingFailedView()
                        }
                    }
                    .sheet(isPresented: $showTagSheet, onDismiss: {
                        // FIXME: this method is an addSnapshotListener, so is it necessary?
                        // When the tags change, we want to immediately update the folder songs which will not happen due to the way they're fetched
                        if let selectedFolder {
                            mainViewModel.fetchSongs(selectedFolder)
                        }
                    }) {
                        if let selectedSong = selectedSong {
                            let tags: [TagSelectionEnum] = selectedSong.tags?.compactMap { TagSelectionEnum(rawValue: $0) } ?? []
                            SongTagView(isPresented: $showTagSheet, tagsToUpdate: .constant([]), tags: tags, song: selectedSong)
                        } else {
                            LoadingFailedView()
                        }
                    }
                    .confirmationDialog("\(selectedSong?.id ?? "" == uid() ? "Delete" : "Leave") Song", isPresented: $showSongDeleteSheet) {
                        if let selectedSong = selectedSong {
                            Button(songViewModel.isShared(selectedSong) ? "Leave" : "Delete", role: .destructive) {
                                if !songViewModel.isShared(selectedSong) {
                                    songViewModel.moveSongToRecentlyDeleted(selectedSong)
                                } else {
                                    songViewModel.leaveSong(song: selectedSong)
                                }
                            }
                        } else {
                            LoadingFailedView()
                        }
                    }
                    .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                        let animation = Animation.easeInOut(duration: 0.22)
                        let value = (value.first ?? 0)
                        
                        DispatchQueue.main.async {
//                            withAnimation(.easeInOut(duration: 0.1)) {
                                showCollapsedNavBarDivider = (hasHomeButton() ? value <= 100 : value <= 145) // FIXME: fix divider showing when it shouldn't
//                            }
                        }
                        DispatchQueue.main.async {
//                            withAnimation(animation) {
                                showCollapsedNavBarTitle = value <= 80
//                            }
                        }
                        DispatchQueue.main.async {
//                            withAnimation(animation) {
                                showCollapsedNavBar = !(value <= -12)
//                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
}
