//
//  MainView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import SwiftUI
import MobileCoreServices
import FASwiftUI
#if os(iOS)
import BottomSheet
#endif

struct MainView: View {
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @ObservedObject var networkManager = NetworkManager()
    @ObservedObject var sortViewModel = SortViewModel()
    @ObservedObject var notificationManager = NotificationManager()
    
    @AppStorage(firstTimeLocalDataKey) var firstTimeLocalData: Bool = true
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    @FocusState var isSearching: Bool
    
    
    @State var newFolder = ""
    
    @State var selectedSong: Song?
    
    @State var showMenu = false
    @State var showNewSong = false
    @State var showNewFolder = false
    @State var showDeleteSheet = false
    @State var showEditSheet = false
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
        if songSearchText.isEmpty {
            return mainViewModel.songs.sorted(by: { (song1, song2) -> Bool in
                switch sortSelection {
                case .noSelection:
                    return false
                case .name:
                    return song1.title < song2.title
                case .artist:
                    return song1.artist ?? "" < song2.artist ?? ""
                case .key:
                    return song1.key ?? "" < song2.key ?? ""
                case .dateCreated:
                    return song1.timestamp < song2.timestamp
                case .pins:
                    return song1.pinned ?? false && !(song2.pinned ?? false)
                }
            })
        } else {
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
                    return song1.key ?? "" < song2.key ?? ""
                case .dateCreated:
                    return song1.timestamp < song2.timestamp
                case .pins:
                    return song1.pinned ?? false && !(song2.pinned ?? false)
                }
            }).filter {
                $0.title.lowercased().contains(lowercasedQuery)
            }
        }
    }

    var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    let persistenceController = PersistenceController()
    
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
        self.selectedFolder = folder
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
            self.selectedFolder = nil
            self.isLoadingFolderSongs = false
        }
    }
    
    init() {
        if networkManager.isConnected {
            mainViewModel.notification = Notification(title: "You're offline", subtitle: "Some features may not work as expected.", imageName: "wifi.slash")
            mainViewModel.notificationStatus = .firebaseNotification
        }
        
        self.mainViewModel.fetchSongs()
        self.mainViewModel.fetchFolders()
        self.mainViewModel.fetchNotificationStatus()
    }
    
    var body: some View {
        NavigationView {
            content
                .onAppear {
                    mainViewModel.fetchSongs()
                    mainViewModel.fetchNotificationStatus()
                    
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
            VStack(spacing: 10) {
                CustomNavBar(title: "Home", navType: .HomeView, folder: nil, showBackButton: false, isEditing: .constant(false))
                    .environmentObject(storeKitManager)
                    .padding(.top)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            Divider()
            ScrollView {
                if storeKitManager.purchasedProducts.isEmpty {
                    AdBannerView(unitId: "ca-app-pub-9538983146851531/4662411532", height: 50)
                        .padding([.leading, .top, .trailing])
                }
                VStack(spacing: 22) {
                    if let notificationStatus = mainViewModel.notificationStatus {
                        if !isSearching {
                            VStack {
                                switch notificationStatus {
                                case .updateAvailable:
                                    NotificationRowView(title: .constant("Update Available"), subtitle: .constant("Tap here to update Live Lyrics. This version may expire soon."), imageName: .constant("arrow.down"), notificationStatus: $mainViewModel.notificationStatus, showNavigationView: .constant(false))
                                case .collaborationChanges:
                                    NotificationRowView(title: .constant(mainViewModel.notification?.title ?? ""), subtitle: .constant(mainViewModel.notification?.subtitle ?? ""), imageName: .constant(mainViewModel.notification?.imageName ?? ""), notificationStatus: $mainViewModel.notificationStatus, showNavigationView: .constant(false))
                                case .firebaseNotification:
                                    NotificationRowView(title: .constant(mainViewModel.notification?.title ?? ""), subtitle: .constant(mainViewModel.notification?.subtitle ?? ""), imageName: .constant(mainViewModel.notification?.imageName ?? ""), notificationStatus: $mainViewModel.notificationStatus, showNavigationView: .constant(false))
                                }
                            }
                        }
                    }
                    VStack {
                        ListHeaderView(title: "Songs")
                        if authViewModel.currentUser?.id ?? "" == "HyeuTQD8PqfGWFzCIf242dFh0P83" || authViewModel.currentUser?.id ?? "" == "0ePGAEVPeGeuUKeAdoezprewzDt1" || authViewModel.currentUser?.id ?? "" == "GqFBjNFXsjVtzGd8mDXNO4Xm6Yf1" {
                            //                            NavigationLink(destination: DefaultSongsView()) {
                            //                                ListRowView(isEditing: $isEditingSongs, title: "All Songs", navArrow: "chevron.right", imageName: nil, icon: nil, subtitleForSong: nil)
                            //                            }
                        }
                        NavigationLink(destination: {
                            RecentlyDeletedView()
                        }) {
                            ListRowView(isEditing: $isEditingSongs, title: "Recently Deleted", navArrow: "chevron.right", imageName: nil, icon: nil, subtitleForSong: nil)
                        }
                    }
                    // MARK: Tools
                    //                    ToolsView()
                    // MARK: Folders
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
                                //                                Button {
                                //                                    withAnimation(.bouncy(extraBounce: 0.1)) {
                                //                                        isEditingFolders.toggle()
                                //                                    }
                                //                                } label: {
                                //                                    ListEditButtonView(isEditing: $isEditingFolders)
                                //                                }
                                Button {
                                    withAnimation(.bouncy(extraBounce: 0.1)) {
                                        isFoldersCollapsed.toggle()
                                    }
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .padding(12)
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
                                                        Text(folder.title)
                                                            .lineLimit(1)
                                                            .multilineTextAlignment(.leading)
                                                        Spacer()
                                                        if isLoadingFolderSongs {
                                                            if selectedFolder?.id == folder.id {
                                                                ProgressView()
                                                            } else {
                                                                Image(systemName: "chevron.right")
                                                                    .foregroundColor(.gray)
                                                            }
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
                                                        Button {
                                                            showEditSheet = true
                                                            selectedFolder = folder
                                                        } label: {
                                                            Label("Edit", systemImage: "pencil")
                                                        }
                                                        .scaleEffect(isEditingFolders ? 0.7 : 1.0)
                                                        Button(role: .destructive) {
                                                            showDeleteSheet = true
                                                            selectedFolder = folder
                                                        } label: {
                                                            Label("Delete", systemImage: "trash")
                                                        }
                                                        .scaleEffect(isEditingFolders ? 1.0 : 0.7)
                                                    }
                                                    .onDrag {
                                                        return NSItemProvider()
                                                    }
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
                                            if !isLoadingFolderSongs && selectedFolder?.id == folder.id && !isEditingFolders && !showEditSheet {
                                                VStack {
                                                    ForEach(sortedSongs(songs: mainViewModel.folderSongs), id: \.id) { song in
                                                        if song.title == "noSongs" {
                                                            Text("No Songs")
                                                                .foregroundColor(Color.gray)
                                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                                .deleteDisabled(true)
                                                                .moveDisabled(true)
                                                        } else {
                                                            NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.folderSongs, restoreSong: nil, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", isDefaultSong: false, albumData: nil, folder: folder)) {
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
#if os(iOS)
                                                                                let pasteboard = UIPasteboard.general
                                                                                pasteboard.string = selectedSong?.title
#else
                                                                                copyToClipboard(text: selectedSong?.title ?? "")
#endif
                                                                            } label: {
                                                                                Label("Copy Title", systemImage: "textformat")
                                                                            }
                                                                            Button {
                                                                                selectedSong = song
#if os(iOS)
                                                                                let pasteboard = UIPasteboard.general
                                                                                pasteboard.string = selectedSong?.lyrics
#else
                                                                                copyToClipboard(text: selectedSong?.lyrics ?? "")
#endif
                                                                            } label: {
                                                                                Label("Copy Lyrics", systemImage: "doc.plaintext")
                                                                            }
                                                                        } label: {
                                                                            Label("Copy", systemImage: "doc")
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
                                                                                print("Deleting song: \(selectedSong.title)")
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
                    // MARK: My Songs
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
                                //                                Button {
                                //                                    withAnimation(.bouncy(extraBounce: 0.1)) {
                                //                                        isEditingSongs.toggle()
                                //                                    }
                                //                                } label: {
                                //                                    ListEditButtonView(isEditing: $isEditingSongs)
                                //                                }
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
                                        .padding(12)
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
                                                    NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.songs, restoreSong: nil, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", isDefaultSong: false, albumData: nil, folder: nil)) {
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
                                    }
                                }
                                .onDrag {
                                    return NSItemProvider()
                                }
                            }
                        }
                    }
                }
                .padding()
                .sheet(isPresented: $showEditSheet, onDismiss: {mainViewModel.fetchFolders()}) {
                    if let selectedFolder = selectedFolder {
                        FolderRowEditView(folder: selectedFolder, showView: $showEditSheet)
                    }
                }
                .confirmationDialog("Delete Folder", isPresented: $showDeleteSheet) {
                    if let selectedFolder = selectedFolder {
                        Button("Delete", role: .destructive) {
                            print("Deleting folder: \(selectedFolder.title)")
                            mainViewModel.deleteFolder(selectedFolder)
                            mainViewModel.fetchFolders()
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                } message: {
                    if let selectedFolder = selectedFolder {
                        Text("Are you sure you want to delete \"\(selectedFolder.title)\"?")
                    }
                }
                .sheet(isPresented: $showSongMoveSheet) {
                    if let selectedSong = selectedSong {
                        AllSongMoveView(song: selectedSong, showProfileView: $showSongMoveSheet, songTitle: selectedSong.title)
                    }
                }
                .sheet(isPresented: $showSongEditSheet, onDismiss: mainViewModel.fetchSongs) {
                    if let selectedSong = selectedSong {
                        SongEditView(song: selectedSong, showProfileView: $showEditSheet, title: .constant(selectedSong.title), key: .constant(selectedSong.key ?? "Not Set"), artist: .constant(selectedSong.artist ?? ""), duration: .constant(selectedSong.duration ?? ""))
                    }
                }
                .confirmationDialog("Delete Song", isPresented: $showSongDeleteSheet) {
                    if let selectedSong = selectedSong {
                        Button("Delete", role: .destructive) {
                            print("Deleting song: \(selectedSong.title)")
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
#if os(iOS)
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = selectedSong?.title
#else
                    copyToClipboard(text: selectedSong?.title ?? "")
#endif
                } label: {
                    Label("Copy Title", systemImage: "textformat")
                }
                Button {
                    selectedSong = song
#if os(iOS)
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = selectedSong?.lyrics
#else
                    copyToClipboard(text: selectedSong?.lyrics ?? "")
#endif
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
