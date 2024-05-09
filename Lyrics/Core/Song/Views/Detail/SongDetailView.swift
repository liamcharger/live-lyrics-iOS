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
    @State var song: Song
    @State var folder: Folder?
    @State var restoreSong: RecentlyDeletedSong?
    @State var selectedVariation: SongVariation?
    
    @State var selectedUser: User?
    
    @State var fetchListener: ListenerRegistration?
    
    @State private var currentIndex = 0
    @State private var value: Int
    @State private var lineSpacing: Double
    @State private var design: Font.Design
    @State private var weight: Font.Weight
    @State private var alignment: TextAlignment
    
    @State var lyrics = ""
    @State var lastUpdatedLyrics = ""
    @State var key = ""
    @State var title = ""
    @State var artist = ""
    @State var errorMessage = ""
    @State var isChecked = ""
    @State var duration = ""
    @State var currentEditorsTitle = ""
    @State var currentEditorsSubtitle = ""
    @State var createdVariationId = ""
    @State var bpm = 120
    @State var bpb = 4
    @State var performanceMode = true
    @State var tags: [String] = []
    
    @State var songIds: [String]?
    @State var fullUsernameString = [String]()
    @State var initials = [String]()
    @State var joinedUsersStrings = [String]()
    @State var lastFetchedJoined: Date?
    
    @State var joinedUsers = [User]()
    
    @State var songVariations = [SongVariation]()
    
    @State var showEditView = false
    @State var showTagSheet = false
    @State var showMoveView = false
    @State var showShareSheet = false
    @State var showSettingsView = false
    @State var wordCountBool = true
    @State var showDeleteSheet = false
    @State var showRestoreSongDeleteSheet = false
    @State var showLeaveSheet = false
    @State var showThesaurusView = false
    @State var showAutoScrollView = false
    @State var showNotesView = false
    @State var showFullScreenView = false
    @State var showSongDataView = false
    @State var showInfo = false
    @State var showAlert = false
    @State var showKickedAlert = false
    @State var showSongRepititionAlert = false
    @State var showPlayViewInfo = false
    @State var showError = false
    @State var showNotesStatusIcon = false
    @State var showNewVariationView = false
    @State var showVariationsManagementSheet = false
    @State var showUserPopover = false
    @State var showJoinedUsers = true
    
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @ObservedObject var recentlyDeletedViewModel = RecentlyDeletedViewModel.shared
    @EnvironmentObject var viewModel: AuthViewModel
    @ObservedObject var notesViewModel: NotesViewModel
    
    @Environment(\.presentationMode) var presMode
    
    @FocusState var isInputActive: Bool
    
    var songs: [Song]?
    let pasteboard = UIPasteboard.general
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
    func getShowVariationCondition() -> Bool {
        if song.uid == viewModel.currentUser?.id ?? "" {
            return true
        }
        
        return !(songVariations.count <= 1)
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
    
    init(song inputSong: Song, songs: [Song]?, restoreSong: RecentlyDeletedSong?, wordCountStyle: String, folder: Folder?) {
        self.songs = songs
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
        self._key = State(initialValue: inputSong.key == "" ? "Not Set" : inputSong.key ?? "Not Set")
        self._artist = State(initialValue: inputSong.artist == "" ? "Not Set" : inputSong.artist ?? "Not Set")
        self._duration = State(initialValue: inputSong.duration ?? "")
        self._bpm = State(initialValue: inputSong.bpm ?? 120)
        self._bpb = State(initialValue: inputSong.bpb ?? 4)
        self._performanceMode = State(initialValue: inputSong.performanceMode ?? true)
        self._tags = State(initialValue: inputSong.tags ?? ["none"])
      
        self.notesViewModel = NotesViewModel(song: inputSong)
 
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
                                    NotesView(notes: $notesViewModel.notes, isLoading: $notesViewModel.isLoading)
                                        .onChange(of: notesViewModel.notes) { notes in
                                            notesViewModel.updateNotes(song, notes: notes)
                                        }
                                }
                                SongDetailMenuView(value: $value, design: $design, weight: $weight, lineSpacing: $lineSpacing, alignment: $alignment, song: song)
                                settings
                            } else {
                                Button(action: {
                                    if let song = restoreSong {
                                        recentlyDeletedViewModel.restoreSong(song: song)
                                    } else {
                                        errorMessage = "There was an error restoring the song."
                                        showError = true
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
                            .lineLimit(1).truncationMode(.tail)
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
                        Text("Key: \(key == "" ? "Not Set" : key)").foregroundColor(Color.gray)
                    }
                    .padding((joinedUsers.count > 0 && showJoinedUsers) ? [] : [.bottom])
                    if joinedUsers.count > 0 && showJoinedUsers {
                        VStack(spacing: 0) {
                            Divider()
                                .padding(.horizontal, -16)
                            ScrollView(.horizontal) {
                                HStack(spacing: 6) {
                                    ForEach(joinedUsers) { user in
                                        Button {
                                            selectedUser = user
                                            showUserPopover = true
                                        } label: {
                                            Text(user.fullname.components(separatedBy: " ").filter { !$0.isEmpty }.reduce("") { ($0 == "" ? "" : "\($0.first!)") + "\($1.first!)" })
                                                .padding(12)
                                                .font(.system(size: 16).weight(.medium))
                                                .background(Material.regular)
                                                .clipShape(Circle())
                                                .overlay {
                                                    if song.uid == user.id ?? "" {
                                                        FAText(iconName: "crown", size: 11)
                                                            .foregroundColor(.white)
                                                            .background {
                                                                Circle()
                                                                    .foregroundColor(Color.accentColor)
                                                                    .frame(width: 22, height: 22)
                                                            }
                                                            .offset(x: 15, y: -13)
                                                            .shadow(radius: 3)
                                                    }
                                                }
                                        }
                                        .modifier(UserPopover(isPresented: $showUserPopover, joinedUsers: $joinedUsers, selectedUser: $selectedUser, user: user, song: song))
                                    }
                                }
                                .padding(12)
                            }
                            .padding(.horizontal, -16)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal)
            }
            Divider()
            TextEditor(text: (song.readOnly ?? false) == true || songs == nil ? .constant(lyrics) : $lyrics)
                .multilineTextAlignment(alignment)
                .font(.system(size: CGFloat(value), weight: weight, design: design))
                .lineSpacing(lineSpacing)
                .focused($isInputActive)
                .padding(.leading, 11)
            Divider()
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
                                        if song.uid == viewModel.currentUser?.id ?? "" {
                                            `default`
                                        } else if song.uid != viewModel.currentUser?.id ?? "" && songVariations.contains(where: { $0.title == SongVariation.defaultId }) {
                                            `default`
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
                                        if song.uid == viewModel.currentUser?.id ?? "" {
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
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal)
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            wordCountBool = viewModel.currentUser?.wordCount ?? true
            songViewModel.fetchSongVariations(song: song) { variations in
                if let variationIds = song.variations, !variations.isEmpty {
                    var fullVariations = [SongVariation]()
                    if variationIds.contains(where: { $0 == SongVariation.defaultId }) {
                        fullVariations.append(SongVariation(title: SongVariation.defaultId, lyrics: "", songUid: "", songId: ""))
                    }
                    
                    let filteredVariations = variations.filter { variation in
                        if let index = variations.firstIndex(where: { $0.id == variation.id ?? "" }), index == 0 {
                            if selectedVariation == nil && !variationIds.contains(where: { $0 == SongVariation.defaultId }) {
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
                    
                    fullVariations.append(contentsOf: filteredVariations)
                    
                    self.songVariations = fullVariations
                } else {
                    self.songVariations = variations
                }
            }
            songViewModel.fetchSong(listen: true, forUser: song.uid, song.id ?? "") { song in
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
                        return "Not Set"
                    }
                }()
                self.artist = song.artist ?? ""
                self.duration = song.duration ?? ""
                self.tags = song.tags ?? []
                self.design = getDesign(design: Int(song.design ?? 0))
                self.weight = getWeight(weight: Int(song.weight ?? 0))
                self.alignment = getAlignment(alignment: Int(song.alignment ?? 0))
                self.value = song.size ?? 18
                self.lineSpacing = song.lineSpacing ?? 1
                self.joinedUsersStrings = song.joinedUsers ?? []
                if !joinedUsersStrings.contains(where: { $0 == viewModel.currentUser?.id ?? "" }) && song.uid != viewModel.currentUser?.id ?? "" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                        showKickedAlert = true
                        presMode.wrappedValue.dismiss()
                    }
                } else {
                    if lastFetchedJoined == nil || lastFetchedJoined!.timeIntervalSinceNow < -10 {
                        let uid = viewModel.currentUser?.id ?? ""
                        if uid != song.uid {
                            joinedUsersStrings.insert(song.uid, at: 0)
                        }
                        if joinedUsersStrings.contains(uid) {
                            if let index = joinedUsersStrings.firstIndex(where: { $0 == uid }) {
                                joinedUsersStrings.remove(at: index)
                            }
                        }
                        viewModel.fetchUsers(uids: joinedUsersStrings) { users in
                            self.lastFetchedJoined = Date()
                            self.joinedUsers = users
                        }
                    }
                }
            } regCompletion: { reg in
                self.fetchListener = reg
            }
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if lyrics != lastUpdatedLyrics {
                    mainViewModel.updateLyrics(forVariation: selectedVariation, song, lyrics: lyrics)
                    lastUpdatedLyrics = lyrics
                }
            }
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            fetchListener?.remove()
            UIApplication.shared.isIdleTimerDisabled = false
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
            Text("Are you sure you want to leave \"\(title)\"? You will lose access immeadiately.")
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert(isPresented: $showKickedAlert) {
            Alert(title: Text("You have been removed as a collaborater by the song owner."), dismissButton: .cancel(Text("OK"), action: {
                presMode.wrappedValue.dismiss()
            }))
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Success"), message: Text("The song was successfully added to your library."), dismissButton: .cancel(Text("Close"), action: {}))
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
            if !(song.readOnly ?? false) {
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
                showMoveView.toggle()
            } label: {
                Label("Move", systemImage: "folder")
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

struct UserPopover: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var joinedUsers: [User]
    @Binding var selectedUser: User?
    
    @State var showRemoveSheet = false
    
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    let user: User?
    let song: Song
    
    func kickButton() -> some View {
        return Group {
            if song.uid == authViewModel.currentUser?.id ?? "" {
                Button {
                    showRemoveSheet = true
                } label: {
                    HStack(spacing: 7) {
                        Text("Remove")
                        FAText(iconName: "square-arrow-right", size: 18)
                    }
                    .foregroundColor(.red)
                    .padding(10)
                    .padding(.horizontal, 8)
                    .background(Material.regular)
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    func popoverContent(style: Int) -> some View {
        return VStack(spacing: 0) {
            if let user = user {
                switch style {
                case 0:
                    VStack(alignment: .trailing) {
                        Button(action: {isPresented = false}) {
                            Image(systemName: "xmark")
                                .imageScale(.medium)
                                .padding(3)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.gray)
                        }
                        VStack(spacing: 12) {
                            Spacer()
                            Text(user.fullname.components(separatedBy: " ").filter { !$0.isEmpty }.reduce("") { ($0 == "" ? "" : "\($0.first!)") + "\($1.first!)" })
                                .font(.system(size: 28).weight(.semibold))
                                .padding(18)
                                .background(Material.regular)
                                .clipShape(Circle())
                            VStack(spacing: 7) {
                                Text(user.username)
                                    .font(.title.weight(.bold))
                                Text(user.fullname)
                                    .foregroundColor(.gray)
                            }
                            kickButton()
                            Spacer()
                            /* if currentlyEditingUsers.contains(where: {$0 == user.id ?? ""}) {
                             HStack(spacing: 12) {
                             FAText(iconName: "pen", size: 23)
                             .padding(14)
                             .background(Color.blue)
                             .foregroundColor(.white)
                             .clipShape(Circle())
                             VStack(alignment: .leading) {
                             Text(user.username)
                             .font(.body.weight(.semibold))
                             Text("is currently editing this song")
                             }
                             }
                             .padding()
                             .frame(maxWidth: .infinity, alignment: .leading)
                             .background(Material.regular)
                             .foregroundColor(.primary)
                             .cornerRadius(20)
                             */
                        }
                        .padding(12)
                        .padding(.bottom, 28)
                        .frame(maxWidth: 225, maxHeight: 195)
                    }
                default:
                    Group {
                        SheetCloseButton(isPresented: $isPresented)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding()
                        VStack(spacing: 12) {
                            Spacer()
                            Text(user.fullname.components(separatedBy: " ").filter { !$0.isEmpty }.reduce("") { ($0 == "" ? "" : "\($0.first!)") + "\($1.first!)" })
                                .font(.system(size: 35).weight(.semibold))
                                .padding(22)
                                .background(Material.regular)
                                .clipShape(Circle())
                            VStack(spacing: 8) {
                                Text(user.username)
                                    .font(.largeTitle.weight(.bold))
                                Text(user.fullname)
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                            kickButton()
                            Spacer()
                            /* if currentlyEditingUsers.contains(where: {$0 == user.id ?? ""}) {
                             HStack(spacing: 12) {
                             FAText(iconName: "pen", size: 23)
                             .padding(14)
                             .background(Color.blue)
                             .foregroundColor(.white)
                             .clipShape(Circle())
                             VStack(alignment: .leading) {
                             Text(user.username)
                             .font(.body.weight(.semibold))
                             Text("is currently editing this song")
                             }
                             }
                             .padding()
                             .frame(maxWidth: .infinity, alignment: .leading)
                             .background(Material.regular)
                             .foregroundColor(.primary)
                             .cornerRadius(20)
                             */
                        }
                    }
                }
            }
        }
        .padding()
        .confirmationDialog("Remove Collaborator?", isPresented: $showRemoveSheet) {
            Button("Remove", role: .destructive) {
                SongViewModel.shared.leaveSong(forUid: user?.id ?? "", song: song)
                if let index = joinedUsers.firstIndex(where: { $0.id ?? "" == user?.id ?? "" }) {
                    joinedUsers.remove(at: index)
                }
                selectedUser = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let user = user {
                Text("Are you sure you want to remove \"\(user.username)\" as a collaborator from this song? They will immediately lose access.")
            }
        }
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            return content
                .popover(isPresented: $isPresented) {
                    popoverContent(style: 0)
                        .presentationCompactAdaptation(.popover)
                }
        } else {
            return content
                .bottomSheet(isPresented: $isPresented, detents: [.medium()]) {
                    popoverContent(style: -1)
                }
        }
    }
}

