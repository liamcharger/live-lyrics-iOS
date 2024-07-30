//
//  SongDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import SwiftUI
import BottomSheet
import SwiftUIIntrospect
import FirebaseFirestore
import TipKit

struct SongDetailView: View {
    @State private var song: Song
    @State private var folder: Folder?
    @State private var restoreSong: RecentlyDeletedSong?
    @State private var selectedVariation: SongVariation?
    
    @State private var selectedUser: User?
    
    @State private var fetchListener: ListenerRegistration?
    
    @State private var currentIndex: Int = 0
    @State private var value: Int
    @State private var lineSpacing: Double
    @State private var design: Font.Design
    @State private var weight: Font.Weight
    @State private var alignment: TextAlignment
    
    @State private var lyrics = ""
    @State private var lastUpdatedLyrics = ""
    @State private var key = ""
    @State private var title = ""
    @State private var artist = ""
    @State private var errorMessage = ""
    @State private var isChecked = ""
    @State private var duration = ""
    @State private var currentEditorsTitle = ""
    @State private var currentEditorsSubtitle = ""
    @State private var createdVariationId = ""
    @State private var bpm = 120
    @State private var bpb = 4
    @State private var performanceMode = true
    @State private var tags: [String] = []
    
    @State private var songIds: [String]?
    @State private var fullUsernameString = [String]()
    @State private var initials = [String]()
    @State private var joinedUsersStrings = [String]()
    @State private var lastFetchedJoined: Date?
    
    @State private var joinedUsers: [User]?
    
    @State private var songVariations = [SongVariation]()
    
    @State private var showEditView = false
    @State private var showTagSheet = false
    @State private var showMoveView = false
    @State private var showShareSheet = false
    @State private var showSettingsView = false
    @State private var wordCountBool = true
    @State private var showDeleteSheet = false
    @State private var showRestoreSongDeleteSheet = false
    @State private var showLeaveSheet = false
    @State private var showThesaurusView = false
    @State private var showAutoScrollView = false
    @State private var showNotesView = false
    @State private var showFullScreenView = false
    @State private var showSongDataView = false
    @State private var showInfo = false
    @State private var showAlert = false
    @State private var showKickedAlert = false
    @State private var showSongRepititionAlert = false
    @State private var showPlayViewInfo = false
    @State private var showNotesStatusIcon = false
    @State private var showNewVariationView = false
    @State private var showVariationsManagementSheet = false
    @State private var showUserPopover = false
    @State private var showJoinedUsers = true
    @State private var showBackgroundBlur = false
    
    @State private var updatedLyricsTimer: Timer?
    
    @State private var activeAlert: ActiveAlert?
    
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel()
    @ObservedObject var recentlyDeletedViewModel = RecentlyDeletedViewModel.shared
    @ObservedObject var notesViewModel = NotesViewModel.shared
    @EnvironmentObject var viewModel: AuthViewModel
    
    @Environment(\.presentationMode) var presMode
    
    @FocusState var isInputActive: Bool
    
    var songs: [Song]?
    let pasteboard = UIPasteboard.general
    let isSongFromFolder: Bool
    private var wordCount: Int {
        let words = lyrics.split { !$0.isLetter }
        return words.count
    }
    private var characterCount: Int {
        let trimmedLyrics = lyrics.replacingOccurrences(of: " ", with: "")
        return trimmedLyrics.count
    }
    private var spaceCount: Int {
        let words = lyrics.split { !$0.isWhitespace }
        return words.count
    }
    private var paragraphCount: Int {
        let paragraphs = lyrics.components(separatedBy: "\n\n")
        return paragraphs.count
    }
    
    func removeFeatAndAfter(from input: String) -> String {
        let keyword = "feat"
        
        if let range = input.range(of: keyword, options: .caseInsensitive) {
            let substring = input[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            return String(substring)
        }
        
        return input
    }
    func getAlignment(alignment: Int) -> TextAlignment {
        switch alignment {
        case 0:
            return .leading
        case 1:
            return .center
        case 2:
            return .trailing
        default:
            return .leading
        }
    }
    func getDesign(design: Int) -> Font.Design {
        switch design {
        case 0:
            return .default
        case 1:
            return .monospaced
        case 2:
            return .rounded
        case 3:
            return .serif
        default:
            return .default
        }
    }
    func getWeight(weight: Int) -> Font.Weight {
        switch weight {
        case 0:
            return .regular
        case 1:
            return .black
        case 2:
            return .bold
        case 3:
            return .heavy
        case 4:
            return .light
        case 5:
            return .medium
        case 6:
            return .regular
        case 7:
            return .semibold
        case 8:
            return .thin
        default:
            return .ultraLight
        }
    }
    func uid() -> String {
        return viewModel.currentUser?.id ?? ""
    }
    func readOnly() -> Bool {
        return (song.readOnly ?? false) || (mainViewModel.selectedFolder?.readOnly ?? false)
    }
    func getShowVariationCondition() -> Bool {
        if (song.variations ?? []).isEmpty && !(song.readOnly ?? false) {
            return true
        } else if songVariations.count < 1 && song.readOnly ?? false {
            return false
        }
        return songVariations.count > 1
    }
    func fetchUsers() {
        if lastFetchedJoined == nil || lastFetchedJoined!.timeIntervalSinceNow < -10 {
            if uid() != song.uid {
                joinedUsersStrings.insert(song.uid, at: 0)
            }
            if joinedUsersStrings.contains(uid()) {
                if let index = joinedUsersStrings.firstIndex(where: { $0 == uid() }) {
                    joinedUsersStrings.remove(at: index)
                }
            }
            viewModel.fetchUsers(uids: joinedUsersStrings) { users in
                self.lastFetchedJoined = Date()
                self.joinedUsers = users
            }
        }
    }
    func checkForUpdatedLyrics() {
        self.updatedLyricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if lyrics != lastUpdatedLyrics {
                mainViewModel.updateLyrics(forVariation: selectedVariation, song, lyrics: lyrics)
                lastUpdatedLyrics = lyrics
            }
        }
    }
    
    enum ActiveAlert {
        case kickedOut, error
    }
    
    var playButton: some View {
        Button(action: {showFullScreenView.toggle()}, label: {
            Image(systemName: "play")
                .padding()
                .font(.body.weight(.semibold))
                .foregroundColor(.blue)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.blue, lineWidth: 2.5)
                }
        })
    }
    
    init(song inputSong: Song, songs: [Song]?, restoreSong: RecentlyDeletedSong? = nil, wordCountStyle: String, folder: Folder? = nil, joinedUsers: [User]? = nil, isSongFromFolder: Bool? = nil) {
        self.songs = songs
        self.isSongFromFolder = isSongFromFolder ?? false
        self._joinedUsers = State(initialValue: joinedUsers)
        self._isChecked = State(initialValue: wordCountStyle)
        self._restoreSong = State(initialValue: restoreSong)
        self._value = State(initialValue: inputSong.size ?? 18)
        self._lineSpacing = State(initialValue: inputSong.lineSpacing ?? 1.0)
        self._design = State(initialValue: .default)
        self._weight = State(initialValue: .regular)
        self._alignment = State(initialValue: .leading)
        self._folder = State(initialValue: folder)
        self._song = State(initialValue: inputSong)
        self._lyrics = State(initialValue: inputSong.lyrics)
        self._lastUpdatedLyrics = State(initialValue: inputSong.lyrics)
        self._title = State(initialValue: inputSong.title)
        self._currentIndex = State(initialValue: inputSong.order ?? 0)
        self._key = State(initialValue: inputSong.key == "" ? NSLocalizedString("not_set", comment: "") : inputSong.key ?? NSLocalizedString("not_set", comment: ""))
        self._artist = State(initialValue: inputSong.artist == "" ? NSLocalizedString("not_set", comment: "") : inputSong.artist ?? NSLocalizedString("not_set", comment: ""))
        self._duration = State(initialValue: inputSong.duration ?? "")
        self._bpm = State(initialValue: inputSong.bpm ?? 120)
        self._bpb = State(initialValue: inputSong.bpb ?? 4)
        self._performanceMode = State(initialValue: inputSong.performanceMode ?? true)
        self._tags = State(initialValue: inputSong.tags ?? ["none"])
 
        self._design = State(initialValue: getDesign(design: Int(inputSong.design ?? 0)))
        self._weight = State(initialValue: getWeight(weight: Int(inputSong.weight ?? 0)))
        self._alignment = State(initialValue: getAlignment(alignment: Int(inputSong.alignment ?? 0)))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack {
                VStack(spacing: 12) {
                    HStack {
                        Button(action: {presMode.wrappedValue.dismiss()}, label: {
                            Image(systemName: "chevron.left")
                                .padding(18)
                                .font(.body.weight(.semibold))
                                .background(Material.regular)
                                .foregroundColor(.primary)
                                .clipShape(Circle())
                        })
                        Spacer()
                        if !isInputActive {
                            if songs != nil {
                                if #available(iOS 17, *) {
                                    playButton
                                        .showPlayViewTip()
                                } else {
                                    playButton
                                }
                                Button(action: {showNotesView.toggle()}, label: {
                                    FAText(iconName: "book", size: 18)
                                        .modifier(NavBarButtonViewModifier())
                                        .overlay {
                                            if notesViewModel.notes != "" {
                                                Circle()
                                                    .frame(width: 11, height: 11)
                                                    .foregroundColor(.blue)
                                                    .offset(x: 17, y: -18)
                                            }
                                        }
                                })
                                .sheet(isPresented: $showNotesView) {
                                    NotesView(song: song)
                                }
                                settings
                            } else {
                                Button(action: {
                                    if let song = restoreSong {
                                        recentlyDeletedViewModel.restoreSong(song: song)
                                    } else {
                                        errorMessage = "There was an error restoring the song."
                                        showAlert = true
                                        activeAlert = .error
                                    }
                                    presMode.wrappedValue.dismiss()
                                }, label: {
                                    FAText(iconName: "rotate-left", size: 18)
                                        .padding()
                                        .font(.body.weight(.semibold))
                                        .background(Material.regular)
                                        .foregroundColor(.primary)
                                        .clipShape(Circle())
                                })
                                Button(action: {
                                    self.showRestoreSongDeleteSheet = true
                                }, label: {
                                    FAText(iconName: "trash-can", size: 18)
                                        .padding()
                                        .font(.body.weight(.semibold))
                                        .background(Material.regular)
                                        .foregroundColor(.primary)
                                        .clipShape(Circle())
                                })
                                .confirmationDialog("Delete Song", isPresented: $showRestoreSongDeleteSheet) {
                                    Button("Delete", role: .destructive) {
                                        mainViewModel.deleteSong(song: restoreSong!)
                                        presMode.wrappedValue.dismiss()
                                    }
                                    Button("Cancel", role: .cancel) { }
                                } message: {
                                    Text("Are you sure you want to permanently delete \"\(restoreSong!.title)\"?")
                                }
                            }
                        } else {
                            Button(action: {isInputActive = false}, label: {
                                Text("Done")
                                    .padding()
                                    .font(.body.weight(.semibold))
                                    .background(Material.regular)
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                            })
                        }
                    }
                    HStack(alignment: .center, spacing: 10) {
                        Text(title)
                            .font(.system(size: 24, design: .rounded).weight(.bold))
                            .lineLimit(1)
                        if tags.count > 0 {
                            HStack(spacing: 5) {
                                ForEach(tags, id: \.self) { tag in
                                    Circle()
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(songViewModel.getColorForTag(tag))
                                }
                            }
                        }
                        Spacer()
                        Text("Key: \(key == "" ? NSLocalizedString("not_set", comment: "") : key)").foregroundColor(Color.gray)
                    }
                    .padding(.bottom)
                }
                .padding(.top, 8)
                .padding(.horizontal)
            }
            Divider()
            ZStack {
                let showJoinedUsers = joinedUsers?.isEmpty ?? true
                
                CustomTextEditor(text: $lyrics,
                                 multilineTextAlignment: .leading,
                                 font: UIFont.systemFont(ofSize: CGFloat(value), weight: weight.uiFontWeight),
                                 lineSpacing: lineSpacing,
                                 padding: UIEdgeInsets(top: showJoinedUsers ? 12 : 75, left: 12, bottom: 12, right: 12),
                                 isInputActive: $isInputActive,
                                 showBlur: $showBackgroundBlur)
                .focused($isInputActive)
                if !readOnly() || showJoinedUsers {
                    if !showJoinedUsers {
                        VisualEffectBlur(blurStyle: .dark)
                            .mask(LinearGradient(
                                gradient: Gradient(colors: [Color.black, Color.clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(height: 80)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .opacity(showBackgroundBlur ? 1 : 0)
                    }
                    VStack {
                        ZStack {
                            if let joinedUsers = joinedUsers {
                                ScrollView(.horizontal) {
                                    HStack(spacing: 6) {
                                        ForEach(joinedUsers, id: \.id) { user in
                                            Button {
                                                selectedUser = user
                                                showUserPopover = true
                                            } label: {
                                                UserPopoverRowView(user: user, song: song)
                                            }
                                        }
                                    }
                                    .padding(10)
                                }
                            }
                            if !showJoinedUsers {
                                VisualEffectBlur(blurStyle: .dark)
                                    .mask(LinearGradient(
                                        gradient: Gradient(colors: [Color.clear, Color.black]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(width: 300)
                                    .mask(LinearGradient(
                                        gradient: Gradient(colors: [Color.clear, Color.black]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    ))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            if !readOnly() {
                                HStack {
                                    Spacer()
                                    SongDetailMenuView(value: $value, design: $design, weight: $weight, lineSpacing: $lineSpacing, alignment: $alignment, song: song)
                                }
                                .padding()
                            }
                        }
                        .frame(height: 70)
                        Spacer()
                    }
                }
            }
            Divider()
            if restoreSong == nil {
                VStack(spacing: 14) {
                    if #available(iOS 17, *) {
                        TipView(VariationsTip())
                    }
                    HStack {
                        if !getShowVariationCondition() {
                            Spacer()
                        }
                        if songs != nil {
                            if wordCountBool {
                                Group {
                                    if isChecked == "Words" {
                                        Text("\(wordCount) \((wordCount == 1) ? "Word" : "Words")")
                                    } else if isChecked == "Characters" {
                                        Text("\(characterCount) \((characterCount == 1) ? "Character" : "Characters")")
                                    } else if isChecked == "Spaces" {
                                        Text("\(spaceCount) \((spaceCount == 1) ? "Space" : "Spaces")")
                                    } else if isChecked == "Paragraphs" {
                                        Text("\(paragraphCount) \((paragraphCount == 1) ? "Paragraph" : "Paragraphs")")
                                    }
                                }
                                .foregroundColor(.primary)
                                .font(.system(size: 16).weight(.semibold))
                            }
                        }
                        if getShowVariationCondition() {
                            Spacer()
                            Group {
                                if songViewModel.isLoadingVariations {
                                    ProgressView()
                                } else {
                                    if songVariations.isEmpty {
                                        Button {
                                            showNewVariationView = true
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "plus")
                                                Text("New Variation")
                                            }
                                        }
                                    } else {
                                        Menu {
                                            let `default` = Group {
                                                Button {
                                                    self.lyrics = song.lyrics
                                                    self.selectedVariation = nil
                                                } label: {
                                                    Label("Default", systemImage: selectedVariation == nil ? "checkmark" : "")
                                                }
                                                Divider()
                                            }
                                            if (song.variations ?? []).isEmpty {
                                                `default`
                                            } else {
                                                if song.uid == uid() {
                                                    `default`
                                                } else if song.uid != uid() && songVariations.contains(where: { $0.title == SongVariation.defaultId }) {
                                                    `default`
                                                }
                                            }
                                            ForEach(songVariations, id: \.id) { variation in
                                                if variation.title != SongVariation.defaultId {
                                                    Button {
                                                        self.selectedVariation = variation
                                                        self.lyrics = variation.lyrics
                                                    } label: {
                                                        Label(variation.title, systemImage: (variation.id ?? "" == selectedVariation?.id ?? "") ? "checkmark" : "")
                                                    }
                                                }
                                            }
                                            if !readOnly() {
                                                if song.uid == uid() || (song.variations ?? []).isEmpty {
                                                    Divider()
                                                    if songVariations.count > 0 {
                                                        Button {
                                                            showVariationsManagementSheet = true
                                                        } label: {
                                                            Label("Manage", systemImage: "gear")
                                                        }
                                                    }
                                                    Button {
                                                        showNewVariationView = true
                                                    } label: {
                                                        Label("New", systemImage: "square.and.pencil")
                                                    }
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 5) {
                                                if let variation = selectedVariation {
                                                    Text(variation.title)
                                                } else {
                                                    Text("Default")
                                                }
                                                Image(systemName: "chevron.up.chevron.down")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if !wordCountBool || !getShowVariationCondition() {
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal)
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert, content: {
            if let activeAlert = activeAlert {
                switch activeAlert {
                case .kickedOut:
                    return Alert(title: Text("You no longer have access to this song."), dismissButton: .cancel(Text("OK"), action: {
                        presMode.wrappedValue.dismiss()
                    }))
                case .error:
                    return Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
                }
            }
            return Alert(title: Text("Error"), message: Text("An unknown error has occured."), dismissButton: .cancel())
        })
        .onAppear {
            wordCountBool = viewModel.currentUser?.wordCount ?? true
            songViewModel.fetchSongVariations(song: song) { variations in
                if let variationIds = song.variations, !variations.isEmpty {
                    var fullVariations = [SongVariation]()
                    if variationIds.contains(where: { $0 == SongVariation.defaultId }) || (song.variations ?? []).isEmpty {
                        fullVariations.append(SongVariation(title: SongVariation.defaultId, lyrics: "", songUid: "", songId: ""))
                    }
                    
                    let filteredVariations = variations.filter { variation in
                        if variationIds.isEmpty {
                            return true
                        } else {
                            if let index = variations.firstIndex(where: { $0.id == variation.id ?? "" }), index == 0 {
                                if !variationIds.contains(where: { $0 == SongVariation.defaultId }) {
                                    selectedVariation = variation
                                }
                            }
                            if let selectedVariation = selectedVariation, selectedVariation.id ?? "" == variation.id ?? "" && !isInputActive {
                                self.lyrics = variation.lyrics
                            } else {
                                if !isInputActive {
                                    self.lyrics = song.lyrics
                                }
                            }
                            
                            return variationIds.contains(variation.id ?? "")
                        }
                    }
                    
                    fullVariations.append(contentsOf: filteredVariations)
                    
                    self.songVariations = fullVariations
                } else {
                    self.songVariations = variations
                }
            }
            songViewModel.fetchSong(listen: true, forUser: song.uid, song.id!) { song in
                if let song = song {
                    self.title = song.title
                    if !isInputActive {
                        if selectedVariation == nil {
                            self.lyrics = song.lyrics
                        }
                    }
                    self.key = {
                        if let key = song.key, !key.isEmpty {
                            return key
                        } else {
                            return NSLocalizedString("not_set", comment: "")
                        }
                    }()
                    self.artist = song.artist ?? ""
                    self.duration = song.duration ?? ""
                    // Only refresh the tags if the song isn't shared because it's already been inherited from the SharedSong
                    if !songViewModel.isShared(song: song) {
                        self.tags = song.tags ?? []
                    }
                    self.design = getDesign(design: Int(song.design ?? 0))
                    self.weight = getWeight(weight: Int(song.weight ?? 0))
                    self.alignment = getAlignment(alignment: Int(song.alignment ?? 0))
                    self.value = song.size ?? 18
                    self.lineSpacing = song.lineSpacing ?? 1
                    if joinedUsers == nil {
                        if let folder = folder, folder.id! != uid() {
                            self.joinedUsersStrings = folder.joinedUsers ?? []
                        } else {
                            self.joinedUsersStrings = song.joinedUsers ?? []
                        }
                        if !joinedUsersStrings.contains(where: { $0 == uid() }) && song.uid != uid() {
                            showAlert = true
                            activeAlert = .kickedOut
                        } else {
                            fetchUsers()
                        }
                    }
                }
            } regCompletion: { reg in
                self.fetchListener = reg
            }
            checkForUpdatedLyrics()
            notesViewModel.fetchNotes(song: song)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            updatedLyricsTimer?.invalidate()
            updatedLyricsTimer = nil
            fetchListener?.remove()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .bottomSheet(isPresented: $showUserPopover, detents: [.medium()]) {
            if let folder = mainViewModel.selectedFolder, mainViewModel.folderSongs.contains(where: { $0.id! == song.id! }) {
                UserPopover(joinedUsers: $joinedUsers, selectedUser: $selectedUser, song: song, folder: folder, isSongFromFolder: isSongFromFolder)
            } else {
                UserPopover(joinedUsers: $joinedUsers, selectedUser: $selectedUser, song: song, folder: nil, isSongFromFolder: isSongFromFolder)
            }
        }
        .confirmationDialog("Delete Song", isPresented: $showDeleteSheet) {
            Button("Delete", role: .destructive) {
                self.songViewModel.moveSongToRecentlyDeleted(song)
                self.presMode.wrappedValue.dismiss()
            }
            if let folder = folder {
                Button("Remove from Folder") {
                    self.songViewModel.moveSongToRecentlyDeleted(folder, song)
                    self.presMode.wrappedValue.dismiss()
                }
            }
            Button("Cancel", role: .cancel) {
                self.selectedVariation = nil
            }
        } message: {
            Text("Are you sure you want to delete \(selectedVariation == nil ? "\"" + title : "the variation \"" + (selectedVariation?.title ?? ""))\"?")
        }
        .confirmationDialog("Leave Song", isPresented: $showLeaveSheet) {
            Button("Leave", role: .destructive) {
                // Check if song is part of a shared folder
                if let folder = mainViewModel.selectedFolder, mainViewModel.folderSongs.contains(where: { $0.id ?? "" == song.id ?? "" }) {
                    mainViewModel.leaveCollabFolder(folder: folder)
                } else {
                    self.songViewModel.leaveSong(song: song)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if isSongFromFolder {
                Text("Are you sure you want to leave \"\(title)\"? You will lose access immediately. " + NSLocalizedString("songs_parent_will_be_left", comment: ""))
            } else {
                Text("Are you sure you want to leave \"\(title)\"? You will lose access immediately.")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareView(isDisplayed: $showShareSheet, song: song)
        }
        .sheet(isPresented: $showEditView) {
            SongEditView(song: song, isDisplayed: $showEditView, title: $title, key: $key, artist: $artist, duration: $duration)
        }
        .sheet(isPresented: $showMoveView) {
            SongMoveView(song: song, showProfileView: $showMoveView, songTitle: song.title)
        }
        .sheet(isPresented: $showNewVariationView, onDismiss: {
            if let index = songVariations.firstIndex(where: { $0.id == createdVariationId }) {
                self.selectedVariation = songVariations[index]
                self.lyrics = songVariations[index].lyrics
            }
        }) {
            NewSongVariationView(isDisplayed: $showNewVariationView, createdId: $createdVariationId, song: song)
        }
        .sheet(isPresented: $showTagSheet) {
            let tags: [TagSelectionEnum] = tags.compactMap { TagSelectionEnum(rawValue: $0) }
            SongTagView(isPresented: $showTagSheet, tagsToUpdate: $tags, tags: tags, song: song)
        }
        .sheet(isPresented: $showVariationsManagementSheet) {
            SongVariationManageView(song: song, isDisplayed: $showVariationsManagementSheet, lyrics: $lyrics, selectedVariation: $selectedVariation, songVariations: $songVariations)
        }
        .fullScreenCover(isPresented: $showFullScreenView) {
            PlayView(song: song, size: value, design: design, weight: weight, lineSpacing: lineSpacing, alignment: alignment, key: key, title: title, lyrics: lyrics, duration: {
                if duration.isEmpty {
                    return .constant("")
                } else {
                    return $duration
                }
            }(), bpm: $bpm, bpb: $bpb, performanceMode: $performanceMode, songs: songs ?? [], dismiss: $showFullScreenView)
        }
        .onChange(of: isInputActive) { isInputActive in
            withAnimation(.bouncy(duration: 0.4)) {
                if isInputActive {
                    showJoinedUsers = false
                } else {
                    showJoinedUsers = true
                }
            }
        }
    }
    
    var settings: some View {
        Menu {
            if !readOnly() {
                Button {
                    showEditView.toggle()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            if !songViewModel.isShared(song: song) {
                Button {
                    showShareSheet.toggle()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            Button {
                let printController = UIPrintInteractionController.shared
                
                let printInfo = UIPrintInfo(dictionary: nil)
                printInfo.outputType = UIPrintInfo.OutputType.general
                printInfo.jobName = song.title
                printController.printInfo = printInfo
                
                let artistString = song.artist?.isEmpty == false ? "<div style='color: gray;'>\(song.artist!)</div>" : ""
                
                let htmlString = """
<html>
<head>
<style>
    body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
        margin: 0;
        padding: 34px;
        box-sizing: border-box;
    }
    .content {
        column-count: 2;
        column-gap: 20px;
        column-fill: auto; /* Ensure the columns fill equally */
    }
    h2 {
        margin-bottom: 5px;
    }
    .gray-text {
        color: gray;
    }
</style>
</head>
<body>
<div>
    <h2>\(song.title)</h2>
    \(artistString)
</div>
<br/>
<div class="content">
    \(lyrics.replacingOccurrences(of: "\n", with: "<br/>"))
</div>
</body>
</html>
"""
                
                let formatter = UIMarkupTextPrintFormatter(markupText: htmlString)
                formatter.perPageContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                printController.printFormatter = formatter
                
                printController.present(animated: true, completionHandler: nil)
            } label: {
                Label("Print", systemImage: "printer")
            }
            let move = Button {
                showMoveView.toggle()
            } label: {
                Label("Move", systemImage: "folder")
            }
            if let selectedFolder = mainViewModel.selectedFolder, isSongFromFolder {
                if selectedFolder.uid ?? "" == uid() {
                    move
                }
            } else {
                move
            }
            Menu {
                Button {
                    self.pasteboard.string = title
                } label: {
                    Label("Copy Title", systemImage: "textformat")
                }
                Button {
                    self.pasteboard.string = lyrics
                } label: {
                    Label("Copy Lyrics", systemImage: "doc.plaintext")
                }
                #if DEBUG
                Button {
                    self.pasteboard.string = song.id ?? ""
                } label: {
                    Label("Copy Song ID", systemImage: "doc.on.doc")
                }
                #endif
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            if !(song.readOnly ?? false) {
                Button {
                    showTagSheet = true
                } label: {
                    Label("Tags", systemImage: "tag")
                }
            }
            Button(role: .destructive, action: {
                if !songViewModel.isShared(song: song) {
                    showDeleteSheet = true
                } else {
                    showLeaveSheet = true
                }
            }, label: {
                if songViewModel.isShared(song: song) {
                    Label("Leave", systemImage: "arrow.backward.square")
                } else {
                    Label("Delete", systemImage: "trash")
                }
            })
        } label: {
            FAText(iconName: "ellipsis", size: 18)
                .modifier(NavBarButtonViewModifier())
        }
    }
}
