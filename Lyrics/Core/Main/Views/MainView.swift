//
//  MainView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import SwiftUI
import MobileCoreServices
#if os(iOS)
import BottomSheet
#endif

struct MainView: View {
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var sortViewModel = SortViewModel.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    @FocusState var isSearching: Bool
    
    @State var selectedSong: Song?
    @State var draggedSong: Song?
    
    @State var draggedFolder: Folder?
    
    @State var hasFirestoreStartedListening = false
    @State var showMenu = false
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
    @State var showSharedSongsSearch = false
    @State var isLoadingFolderSongs = false
    @State var displayFolderSongsSheet = false
    @State var openedFolder = false
    @State var showSortSheet = false
    
    @State var folderSearchText = ""
    @State var songSearchText = ""
    @State var sharedSongSearchText = ""
    @State var newFolder = ""
    
    @State var notificationStatus: NotificationStatus?
    // Property allows folder to check if it should be displaying its songs or not. selectedFolder is used for external views, such as SongMoveView, SongEditView, etc..
    @State var selectedFolderForFolderUse: Folder?
    
    @State var sortSelection: SortSelectionEnum = .noSelection
    
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
        
        return songs.sorted(by: { (song1, song2) -> Bool in
            switch sortSelection {
            case .noSelection:
                return false
            case .name:
                return song1.title < song2.title
            case .artist:
                return song1.artist ?? "" < song2.artist ?? ""
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
            return song1.pinned ?? false && !(song2.pinned ?? false)
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
    
    var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    let pasteboard = UIPasteboard.general
    let networkManager = NetworkManager.shared
    
    func sortedSongs(songs: [Song]) -> [Song] {
        return songs.sorted(by: { (song1, song2) -> Bool in
            return song1.pinned ?? false && !(song2.pinned ?? false)
        })
    }
    
    func move(from source: IndexSet, to destination: Int) {
        mainViewModel.folders.move(fromOffsets: source, toOffset: destination)
        mainViewModel.updateFolderOrder()
        mainViewModel.fetchFolders()
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let folder = mainViewModel.folders[index]
            mainViewModel.deleteFolder(folder)
        }
        mainViewModel.fetchFolders()
    }
    func clearSearch() {
        self.songSearchText = ""
        self.folderSearchText = ""
    }
    func openFolder(_ folder: Folder) {
        self.openedFolder = true
        self.selectedFolderForFolderUse = folder
        self.mainViewModel.folderSongs = []
        self.mainViewModel.selectedFolder = folder
        self.mainViewModel.fetchSongs(folder)
        self.isLoadingFolderSongs = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.bouncy) {
                isLoadingFolderSongs = false
            }
        }
    }
    func closeFolder() {
        withAnimation(.bouncy) {
            self.openedFolder = false
            self.selectedFolderForFolderUse = nil
            self.mainViewModel.selectedFolder = nil
            self.isLoadingFolderSongs = false
        }
    }
    func uid() -> String {
        return authViewModel.currentUser?.id ?? ""
    }
    
    var body: some View {
        NavigationView {
            content
                .onAppear {
                    DispatchQueue.main.async {
                        if !networkManager.getNetworkState() {
                            mainViewModel.notification = Notification(title: "You're offline", subtitle: "Some features may not work as expected.", imageName: "wifi.slash")
                            mainViewModel.notificationStatus = .network
                        }
                        
                        if !hasFirestoreStartedListening {
                            self.mainViewModel.fetchSongs()
                            self.mainViewModel.fetchFolders()
                            self.mainViewModel.fetchSharedSongs()
                            self.mainViewModel.fetchSharedFolders()
                            self.mainViewModel.fetchInvites()
                            self.mainViewModel.fetchNotificationStatus()
                            self.hasFirestoreStartedListening = true
                        }
                    }
                    sortViewModel.loadFromUserDefaults { sortSelection in
                        self.sortSelection = sortSelection
                    }
                }
                .onChange(of: networkManager.getNetworkState()) { state in
                    if state && notificationStatus == .network {
                        mainViewModel.notificationStatus = nil
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                CustomNavBar(title: "Home", navType: .HomeView, folder: nil, showBackButton: false, isEditing: .constant(false))
                    .environmentObject(storeKitManager)
                    .padding(.top)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            Divider()
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    AdBannerView(unitId: "ca-app-pub-5671219068273297/1814470464", height: 80, paddingTop: 16, paddingLeft: 16, paddingBottom: 0, paddingRight: 16)
                    VStack(spacing: 22) {
                        if let notificationStatus = mainViewModel.notificationStatus {
                            if !isSearching {
                                VStack {
                                    switch notificationStatus {
                                    case .updateAvailable:
                                        NotificationRowView(title: "Update Available", subtitle: "Tap here to update Live Lyrics. This version may expire soon.", imageName: "arrow.down", notificationStatus: $mainViewModel.notificationStatus, isDisplayed: .constant(false))
                                    case .collaborationChanges:
                                        NotificationRowView(title: mainViewModel.notification?.title ?? "", subtitle: mainViewModel.notification?.subtitle ?? "", imageName: mainViewModel.notification?.imageName ?? "", notificationStatus: $mainViewModel.notificationStatus, isDisplayed: .constant(false))
                                    case .firebaseNotification, .network:
                                        if let notification = mainViewModel.notification {
                                            NotificationRowView(title: notification.title, subtitle: notification.subtitle, imageName: notification.imageName, notificationStatus: $mainViewModel.notificationStatus, isDisplayed: .constant(false))
                                        }
                                    }
                                }
                            }
                        }
                        VStack {
                            ListHeaderView(title: "Songs")
                            NavigationLink(destination: {
                                RecentlyDeletedView()
                            }) {
                                ListRowView(isEditing: $isEditingSongs, title: "Recently Deleted", navArrow: "chevron.right")
                            }
                            NavigationLink(destination: {
                                SongShareDetailView()
                            }) {
                                ZStack {
                                    ListRowView(isEditing: $isEditingSongs, title: "Share Invites", navArrow: "chevron.right")
                                    HStack {
                                        Spacer()
                                        if !mainViewModel.incomingShareRequests.isEmpty {
                                            Circle()
                                                .frame(width: 11, height: 11)
                                                .foregroundColor(.blue)
                                                .offset(x: 15, y: -18)
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                        VStack {
                            VStack {
                                HStack {
                                    ListHeaderView(title: "Folders")
                                    Spacer()
                                    Button {
                                        clearSearch()
                                        withAnimation(.bouncy(extraBounce: 0.1)) {
                                            showFolderSearch.toggle()
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
                                        withAnimation(.bouncy(extraBounce: 0.1)) {
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
                                    CustomSearchBar(text: $folderSearchText, imageName: "magnifyingglass", placeholder: "Search")
                                        .padding(.bottom)
                                }
                            }
                            if mainViewModel.isLoadingFolders || mainViewModel.isLoadingSharedFolders {
                                LoadingView()
                            } else {
                                if !isFoldersCollapsed {
                                    ForEach(searchableFolders) { folder  in
                                        if folder.title == "noFolders" {
                                            Text("No Folders")
                                                .foregroundColor(Color.gray)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        } else {
                                            VStack {
                                                HStack {
                                                    Button {
                                                        if openedFolder {
                                                            if selectedFolderForFolderUse?.id == folder.id {
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
                                                                    Text("Shared")
                                                                        .padding(6)
                                                                        .padding(.horizontal, 1.5)
                                                                        .font(.system(size: 13).weight(.medium))
                                                                        .background(Material.thin)
                                                                        .foregroundColor(.primary)
                                                                        .clipShape(Capsule())
                                                                }
                                                            }
                                                            Spacer()
                                                            if selectedFolderForFolderUse?.id == folder.id {
                                                                if isLoadingFolderSongs || mainViewModel.folderSongs.isEmpty {
                                                                    ProgressView()
                                                                } else {
                                                                    Image(systemName: "chevron.right")
                                                                        .foregroundColor(.gray)
                                                                        .rotationEffect(Angle(degrees: !isLoadingFolderSongs && selectedFolderForFolderUse?.id == folder.id ? 90 : 0))
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
                                                                if folder.id ?? "" != uid() {
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
                                                if !isLoadingFolderSongs && selectedFolderForFolderUse?.id == folder.id && !isEditingFolders && !showEditSheet && !mainViewModel.folderSongs.isEmpty {
                                                    VStack {
                                                        if mainViewModel.folderSongs.isEmpty {
                                                            LoadingView()
                                                        } else {
                                                            ForEach(sortedSongs(songs: mainViewModel.folderSongs), id: \.id) { uneditedSong in
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
                                                                    NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.folderSongs, restoreSong: nil, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", folder: folder)) {
                                                                        ListRowView(isEditing: $isEditingFolderSongs, title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "thumbtack" : "", song: song)
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
                                                                                if !songViewModel.isShared(song: song) {
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
                                                                                if !(song.readOnly ?? false) {
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
                                                                                    if songViewModel.isShared(song: song) {
                                                                                        Label("Leave", systemImage: "arrow.backward.square")
                                                                                    } else {
                                                                                        Label("Remove", systemImage: "trash")
                                                                                    }
                                                                                }
                                                                            }
                                                                            .confirmationDialog(songViewModel.isShared(song: selectedSong ?? Song.song) ? "Leave Song" : "Delete Song", isPresented: $showFolderSongDeleteSheet) {
                                                                                if let selectedSong = selectedSong {
                                                                                    Button(songViewModel.isShared(song: selectedSong) ? "Leave" : "Delete", role: .destructive) {
                                                                                        if songViewModel.isShared(song: selectedSong) {
                                                                                            if let selectedFolder = mainViewModel.selectedFolder {
                                                                                                mainViewModel.leaveCollabFolder(folder: selectedFolder)
                                                                                            } else {
                                                                                                songViewModel.leaveSong(song: selectedSong)
                                                                                            }
                                                                                        } else {
                                                                                            songViewModel.moveSongToRecentlyDeleted(selectedSong)
                                                                                        }
                                                                                    }
                                                                                    if !songViewModel.isShared(song: selectedSong) {
                                                                                        Button("Remove from Folder") {
                                                                                            mainViewModel.deleteSong(folder, selectedSong)
                                                                                        }
                                                                                    }
                                                                                    Button("Cancel", role: .cancel) {}
                                                                                }
                                                                            } message: {
                                                                                if let selectedSong = selectedSong {
                                                                                    let isShared = songViewModel.isShared(song: selectedSong)
                                                                                    
                                                                                    Text("Are you sure you want to \(isShared ? "leave" : "delete") \"\(selectedSong.title)\"?") + Text((mainViewModel.selectedFolder != nil && isShared) ? NSLocalizedString("songs_parent_will_be_left", comment: "") : "")
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
                                    ListHeaderView(title: "My Songs")
                                    Spacer()
                                    Button {
                                        clearSearch()
                                        withAnimation(.bouncy(extraBounce: 0.1)) {
                                            self.showSongSearch.toggle()
                                        }
                                    } label: {
                                        Image(systemName: showSongSearch ? "xmark" : "magnifyingglass")
                                            .padding(12)
                                            .foregroundColor(Color.white)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                            .font(.footnote.weight(.bold))
                                    }
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
                                    Button {
                                        withAnimation(.bouncy(extraBounce: 0.1)) {
                                            self.isSongsCollapsed.toggle()
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
                                    CustomSearchBar(text: $songSearchText, imageName: "magnifyingglass", placeholder: "Search")
                                        .padding(.bottom)
                                }
                            }
                            if !isSongsCollapsed {
                                if mainViewModel.isLoadingSongs || mainViewModel.isLoadingSharedSongs {
                                    LoadingView()
                                } else {
                                    ForEach(searchableSongs) { song in
                                        if song.title == "noSongs" {
                                            Text("No Songs")
                                                .foregroundColor(Color.gray)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .deleteDisabled(true)
                                                .moveDisabled(true)
                                        } else {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack {
                                                        NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.songs, restoreSong: nil, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", folder: nil)) {
                                                            ListRowView(isEditing: $isEditingFolderSongs, title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "thumbtack" : "", song: song)
                                                                .contextMenu {
                                                                    songContextMenu(song: song)
                                                                }
                                                        }
                                                        if isEditingSongs {
                                                            Button {
                                                                selectedSong = song
                                                                showSongMoveSheet = true
                                                            } label: {
                                                                ListIconButtonView(imageName: "folder", color: .purple)
                                                            }
                                                            Button {
                                                                selectedSong = song
                                                                showSongEditSheet.toggle()
                                                            } label: {
                                                                ListIconButtonView(imageName: "pencil", color: .blue)
                                                            }
                                                            Button {
                                                                selectedSong = song
                                                                showSongDeleteSheet = true
                                                            } label: {
                                                                ListIconButtonView(imageName: "trash", color: .red)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .onDrag {
                                                sortViewModel.loadFromUserDefaults { sortSelection in
                                                    if sortSelection == .noSelection && song.uid == uid() {
                                                        self.draggedSong = song
                                                    }
                                                }
                                                return NSItemProvider()
                                            }
                                            .onDrop(
                                                of: [.text],
                                                delegate: SongDropViewDelegate(
                                                    destinationItem: song,
                                                    items: $mainViewModel.songs,
                                                    draggedItem: $draggedSong,
                                                    authViewModel: authViewModel
                                                )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .id("songs")
                    }
                    .padding()
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
                    .sheet(isPresented: $showSongMoveSheet) {
                        if let selectedSong = selectedSong {
                            SongMoveView(song: selectedSong, showProfileView: $showSongMoveSheet, songTitle: selectedSong.title)
                        }
                    }
                    .sheet(isPresented: $showSongEditSheet) {
                        if let selectedSong = selectedSong {
                            SongEditView(song: selectedSong, isDisplayed: $showEditSheet, title: .constant(selectedSong.title), key: .constant(selectedSong.key ?? "Not Set"), artist: .constant(selectedSong.artist ?? ""), duration: .constant(selectedSong.duration ?? ""))
                        }
                    }
                    .sheet(isPresented: $showTagSheet) {
                        if let selectedSong = selectedSong {
                            let tags: [TagSelectionEnum] = selectedSong.tags?.compactMap { TagSelectionEnum(rawValue: $0) } ?? []
                            SongTagView(isPresented: $showTagSheet, tagsToUpdate: .constant([]), tags: tags, song: selectedSong)
                        }
                    }
                    .confirmationDialog("Delete Song", isPresented: $showSongDeleteSheet) {
                        if let selectedSong = selectedSong {
                            Button("Delete", role: .destructive) {
                                songViewModel.moveSongToRecentlyDeleted(selectedSong)
                                mainViewModel.fetchSongs()
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    } message: {
                        if let selectedSong = selectedSong {
                            Text("Are you sure you want to delete \"\(selectedSong.title)\"?")
                        }
                    }
                }
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
                if !songViewModel.isShared(song: song) {
                    showSongDeleteSheet.toggle()
                } else {
                    showDeleteSheet.toggle()
                }
            }, label: {
                if songViewModel.isShared(song: song) {
                    Label("Leave", systemImage: "arrow.backward.square")
                } else {
                    Label("Delete", systemImage: "trash")
                }
            })
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthViewModel())
}
