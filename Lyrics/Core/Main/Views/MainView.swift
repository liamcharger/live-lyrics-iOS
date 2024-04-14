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
    
    @State var newFolder = ""
    
    @State var selectedSong: Song?
    @State var draggedSong: Song?
    
    @State var draggedFolder: Folder?
    
    @State var showMenu = false
    @State var showDeleteSheet = false
    @State var showAddSongSheet = false
    @State var showEditSheet = false
    @State var showTagSheet = false
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
    @State var showSongSearch = false
    @State var showFolderSearch = false
    @State var isLoadingFolderSongs = false
    @State var displayFolderSongsSheet = false
    @State var openedFolder = false
    @State var showSortSheet = false
    
    @State var folderSearchText = ""
    @State var songSearchText = ""
    
    @State var notificationStatus: NotificationStatus?
    
    @State var selectedFolder: Folder?
    @State var selectedFolderForFolderUse: Folder?
    
    @State var sortSelection: SortSelectionEnum = .noSelection
    
    var searchableFolders: [Folder] {
        if folderSearchText.isEmpty {
            return mainViewModel.folders
        } else {
            let lowercasedQuery = folderSearchText.lowercased()
            return mainViewModel.folders.filter ({
                $0.title.lowercased().contains(lowercasedQuery)
            })
        }
    }
    var searchableSongs: [Song] {
        let lowercasedQuery = songSearchText.lowercased()
        
        return mainViewModel.songs.sorted(by: { (song1, song2) -> Bool in
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
            self.isLoadingFolderSongs = false
        }
    }
    
    init() {
        if !networkManager.getNetworkState() {
            mainViewModel.notification = Notification(title: "You're offline", subtitle: "Some features may not work as expected.", imageName: "wifi.slash")
            mainViewModel.notificationStatus = .network
        }
        
        self.mainViewModel.fetchSongs()
        self.mainViewModel.fetchFolders()
        self.mainViewModel.fetchNotificationStatus()
    }
    
    var body: some View {
        NavigationView {
            content
                .onAppear {
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
                if storeKitManager.purchasedProducts.isEmpty {
                    AdBannerView(unitId: "ca-app-pub-5671219068273297/1814470464", height: 70)
                        .padding([.leading, .top, .trailing])
                }
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
                            ListRowView(isEditing: $isEditingSongs, title: "Recently Deleted", navArrow: "chevron.right", imageName: nil, icon: nil, subtitleForSong: nil)
                        }
                        NavigationLink(destination: {
                            SongShareDetailView()
                        }) {
                            ListRowView(isEditing: $isEditingSongs, title: "Share Requests", navArrow: "chevron.right", imageName: nil, icon: nil, subtitleForSong: nil)
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
                        if mainViewModel.isLoadingFolders {
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
                                                        Text(folder.title)
                                                            .lineLimit(1)
                                                            .multilineTextAlignment(.leading)
                                                        Spacer()
                                                        if isLoadingFolderSongs {
                                                            if selectedFolderForFolderUse?.id == folder.id {
                                                                ProgressView()
                                                            } else {
                                                                Image(systemName: "chevron.right")
                                                                    .foregroundColor(.gray)
                                                            }
                                                        } else {
                                                            Image(systemName: "chevron.right")
                                                                .foregroundColor(.gray)
                                                                .rotationEffect(Angle(degrees: !isLoadingFolderSongs && selectedFolderForFolderUse?.id == folder.id ? 90 : 0))
                                                        }
                                                    }
                                                    .padding()
                                                    .background(Material.regular)
                                                    .foregroundColor(.primary)
                                                    .clipShape(Capsule())
                                                    .contentShape(.contextMenuPreview, Capsule())
                                                    .contextMenu {
                                                        Button {
                                                            mainViewModel.folderSongs = []
                                                            showEditSheet = true
                                                            selectedFolder = folder
                                                        } label: {
                                                            Label("Edit", systemImage: "pencil")
                                                        }
                                                        Button {
                                                            mainViewModel.fetchSongs(folder)
                                                            selectedFolder = folder
                                                            showAddSongSheet = true
                                                        } label: {
                                                            Label("Add Songs", systemImage: "plus")
                                                        }
                                                        Button(role: .destructive) {
                                                            mainViewModel.folderSongs = []
                                                            showDeleteSheet = true
                                                            selectedFolder = folder
                                                        } label: {
                                                            Label("Delete", systemImage: "trash")
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
                                                        selectedFolder = folder
                                                    } label: {
                                                        ListIconButtonView(imageName: "pencil", color: .blue)
                                                    }
                                                    Button {
                                                        showDeleteSheet = true
                                                        selectedFolder = folder
                                                    } label: {
                                                        ListIconButtonView(imageName: "trash", color: .red)
                                                    }
                                                }
                                            }
                                            if !isLoadingFolderSongs && selectedFolderForFolderUse?.id == folder.id && !isEditingFolders && !showEditSheet {
                                                VStack {
                                                    if mainViewModel.folderSongs.isEmpty {
                                                        LoadingView()
                                                    } else {
                                                        ForEach(sortedSongs(songs: mainViewModel.folderSongs), id: \.id) { song in
                                                            if song.title == "noSongs" {
                                                                Text("No Songs")
                                                                    .foregroundColor(Color.gray)
                                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                                    .deleteDisabled(true)
                                                                    .moveDisabled(true)
                                                            } else {
                                                                NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.folderSongs, restoreSong: nil, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", folder: folder)) {
                                                                    ListRowView(isEditing: $isEditingFolderSongs, title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "thumbtack" : "", icon: nil, subtitleForSong: song)
                                                                        .contextMenu {
                                                                            Button {
                                                                                selectedSong = song
                                                                                songViewModel.fetchSong(selectedSong?.id ?? "") { song in
                                                                                    selectedSong = song
                                                                                }
                                                                                showSongEditSheet.toggle()
                                                                            } label: {
                                                                                Label("Edit", systemImage: "pencil")
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
                                                                                Label("Copy", systemImage: "doc")
                                                                            }
                                                                            Button {
                                                                                selectedFolder = folder
                                                                                selectedSong = song
                                                                                showTagSheet = true
                                                                            } label: {
                                                                                Label("Tags", systemImage: "tag")
                                                                            }
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
                                                                            
                                                                            Button(role: .destructive) {
                                                                                selectedSong = song
                                                                                showFolderSongDeleteSheet.toggle()
                                                                            } label: {
                                                                                Label("Delete", systemImage: "trash")
                                                                            }
                                                                        }
                                                                        .confirmationDialog("Delete Song", isPresented: $showFolderSongDeleteSheet) {
                                                                            if let selectedSong = selectedSong {
                                                                                Button("Delete", role: .destructive) {
                                                                                    songViewModel.moveSongToRecentlyDeleted(selectedSong)
                                                                                    mainViewModel.fetchSongs()
                                                                                }
                                                                                Button("Remove from Folder") {
                                                                                    mainViewModel.deleteSong(folder, selectedSong)
                                                                                }
                                                                                Button("Cancel", role: .cancel) {}
                                                                            }
                                                                        } message: {
                                                                            if let selectedSong = selectedSong {
                                                                                Text("Are you sure you want to delete \"\(selectedSong.title)\"?")
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
                            if mainViewModel.isLoadingSongs {
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
                                                        ListRowView(isEditing: $isEditingFolderSongs, title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "thumbtack" : "", icon: nil, subtitleForSong: song)
                                                            .contextMenu {
                                                                songContextMenu(song: song, showUnpinPinButton: song.pinned ?? false)
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
                                                if sortSelection == .noSelection {
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
                                                draggedItem: $draggedSong
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
                    if let selectedFolder = selectedFolder {
                        FolderEditView(folder: selectedFolder, isDisplayed: $showEditSheet, title: .constant(selectedFolder.title))
                    }
                }
                .sheet(isPresented: $showAddSongSheet, onDismiss: {mainViewModel.fetchSongs(selectedFolder!)}) {
                    if let selectedFolder = selectedFolder {
                        AddSongsView(folder: selectedFolder)
                    }
                }
                .confirmationDialog("Delete Folder", isPresented: $showDeleteSheet) {
                    if let selectedFolder = selectedFolder {
                        Button("Delete", role: .destructive) {
                            mainViewModel.deleteFolder(selectedFolder)
                            mainViewModel.fetchFolders()
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                } message: {
                    if let selectedFolder = selectedFolder {
                        Text("Are you sure you want to permanently delete '\(selectedFolder.title)'? WARNING: This action cannot be undone!")
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
    
    func songContextMenu(song: Song, showUnpinPinButton: Bool) -> some View {
        return VStack {
            Button {
                selectedSong = song
                songViewModel.fetchSong(selectedSong?.id ?? "") { song in
                    selectedSong = song
                }
                showSongEditSheet.toggle()
            } label: {
                Label("Edit", systemImage: "pencil")
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
                Label("Copy", systemImage: "doc")
            }
            Button {
                DispatchQueue.main.async {
                    if showUnpinPinButton {
                        songViewModel.unpinSong(song)
                    } else {
                        songViewModel.pinSong(song)
                    }
                }
            } label: {
                if showUnpinPinButton {
                    Label("Unpin", systemImage: "pin.slash")
                } else {
                    Label("Pin", systemImage: "pin")
                }
            }
            Button {
                selectedSong = song
                showTagSheet = true
            } label: {
                Label("Tags", systemImage: "tag")
            }
            Button(role: .destructive) {
                selectedSong = song
                showSongDeleteSheet.toggle()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthViewModel())
}
