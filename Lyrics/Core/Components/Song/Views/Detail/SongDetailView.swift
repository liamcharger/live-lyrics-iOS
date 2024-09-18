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
    @State private var fontSize: Int
    @State private var lineSpacing: Double
    @State private var weight: Font.Weight
    @State private var alignment: TextAlignment
    
    @State private var lyrics = ""
    @State private var lastUpdatedLyrics = ""
    @State private var key = ""
    @State private var title = ""
    @State private var artist = ""
    @State private var errorMessage = ""
    @State private var wordCountStyle = ""
    @State private var duration = ""
    @State private var createdVariationId = ""
    @State private var bpm = 120
    @State private var bpb = 4
    @State private var performanceMode = true
    @State private var tags: [String] = []
    
    @State private var joinedUsersStrings = [String]()
    @State private var lastFetchedJoined: Date?
    
    @State private var joinedUsers: [User]?
    
    @State private var songVariations = [SongVariation]()
    
    @State private var wordCountBool = true
    @State private var showRestoreSongDeleteSheet = false
    @State private var showPlayView = false
    @State private var showAlert = false
    @State private var showNewVariationView = false
    @State private var showVariationsManagementSheet = false
    @State private var showDatamuseSheet = false
    @State private var showUserPopover = false
    @State private var showJoinedUsers = true
    @State private var showBackgroundBlur = false
    
    @State private var updatedLyricsTimer: Timer?
    
    @State private var activeAlert: ActiveAlert?
    
    @State private var wordType: DatamuseWordType = .synonymn
    
    @AppStorage("showUpgradeSheet") var showUpgradeSheet: Bool = false
    
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var recentlyDeletedViewModel = RecentlyDeletedViewModel.shared
    @ObservedObject var notesViewModel = NotesViewModel.shared
    @ObservedObject var songDetailViewModel = SongDetailViewModel.shared
    @EnvironmentObject var viewModel: AuthViewModel
    
    @Environment(\.presentationMode) var presMode
    @Environment(\.openURL) var openURL
    
    @FocusState var isInputActive: Bool
    
    var songs: [Song]?
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
    
    func getShowVariationCondition() -> Bool {
        if (song.variations ?? []).isEmpty && !(song.readOnly ?? false) {
            return true
        } else if songVariations.count < 1 && song.readOnly ?? false {
            return false
        }
        return songVariations.count > 1
    }
    func fetchUsers() {
        // Prevent joined users from being fetched more than once
        if lastFetchedJoined == nil || lastFetchedJoined!.timeIntervalSinceNow < -10 {
            // User is not the owner, so add the owner to the array
            if songDetailViewModel.uid() != song.uid {
                joinedUsersStrings.insert(song.uid, at: 0)
            }
            // User is not the admin but is a joined user, so remove their profile from the array
            if joinedUsersStrings.contains(songDetailViewModel.uid()) {
                if let index = joinedUsersStrings.firstIndex(where: { $0 == songDetailViewModel.uid() }) {
                    joinedUsersStrings.remove(at: index)
                }
            }
            viewModel.fetchUsers(uids: joinedUsersStrings) { users in
                self.lastFetchedJoined = Date()
                self.joinedUsers = users
            }
        }
    }
    func updateLyrics() {
        mainViewModel.updateLyrics(forVariation: selectedVariation, song, lyrics: lyrics)
        lastUpdatedLyrics = lyrics
    }
    func checkForUpdatedLyrics() {
        // Start a timer to limit lyric updates to once per second, if they have changed
        self.updatedLyricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if lyrics != lastUpdatedLyrics {
                // Lyrics have changed, update them
                updateLyrics()
            }
        }
    }
    func fetchDatamuse(for type: DatamuseWordType) {
        if let user = viewModel.currentUser, user.hasPro ?? false {
            // User has pro, present them with the result
            wordType = type
            WordService.shared.fetchWords(for: songDetailViewModel.selectedText, type: type)
            showDatamuseSheet = true
        } else {
            // User does not have pro, present them with a paywall
            showUpgradeSheet = true
        }
    }
    
    // Use one alert modifer (because more than one alert cannot be applied to the same view) and differentiate show content based on a set var from the enum
    enum ActiveAlert {
        case kickedOut, error
    }
    
    init(song inputSong: Song, songs: [Song]?, restoreSong: RecentlyDeletedSong? = nil, wordCountStyle: String, folder: Folder? = nil, joinedUsers: [User]? = nil, isSongFromFolder: Bool? = nil) {
        self.songs = songs
        self.isSongFromFolder = isSongFromFolder ?? false
        self._joinedUsers = State(initialValue: joinedUsers)
        self._wordCountStyle = State(initialValue: wordCountStyle)
        self._restoreSong = State(initialValue: restoreSong)
        self._fontSize = State(initialValue: inputSong.size ?? 18)
        self._lineSpacing = State(initialValue: inputSong.lineSpacing ?? 1.0)
        
        // Set weight and alignment with an inital value before assigning it a value from the view model to avoid "called before initalized" error
        self._weight = State(initialValue: .regular)
        self._alignment = State(initialValue: .leading)
        
        self._folder = State(initialValue: folder)
        self._song = State(initialValue: inputSong)
        self._lyrics = State(initialValue: inputSong.lyrics)
        self._lastUpdatedLyrics = State(initialValue: inputSong.lyrics)
        self._title = State(initialValue: inputSong.title)
        self._currentIndex = State(initialValue: inputSong.order ?? 0)
        self._key = State(initialValue: inputSong.key ?? "")
        self._artist = State(initialValue: inputSong.artist ?? "")
        self._duration = State(initialValue: inputSong.duration ?? "")
        self._bpm = State(initialValue: inputSong.bpm ?? 120)
        self._bpb = State(initialValue: inputSong.bpb ?? 4)
        self._performanceMode = State(initialValue: inputSong.performanceMode ?? true)
        self._tags = State(initialValue: inputSong.tags ?? ["none"])
        
        self._weight = State(initialValue: songDetailViewModel.getWeight(weight: Int(inputSong.weight ?? 0)))
        self._alignment = State(initialValue: songDetailViewModel.getAlignment(alignment: Int(inputSong.alignment ?? 0)))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack {
                HStack {
                    Button(action: {presMode.wrappedValue.dismiss()}, label: {
                        Image(systemName: "chevron.left")
                            .modifier(NavBarButtonViewModifier())
                    })
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .center, spacing: 6) {
                            Text(title)
                                .font(.system(size: 20, design: .rounded).weight(.bold))
                                .lineLimit(2)
                            if tags.count > 0 {
                                HStack(spacing: 5) {
                                    ForEach(tags, id: \.self) { tag in
                                        Circle()
                                            .frame(width: 12, height: 12)
                                            .foregroundColor(songViewModel.getColorForTag(tag))
                                    }
                                }
                            }
                        }
                        // Only show the text if there is a key or an artist
                        if !key.isEmpty || !artist.isEmpty {
                            Text(key.isEmpty ? artist : "Key: \(key)")
                                .font(.system(size: 15))
                                .foregroundColor(Color.gray)
                        }
                    }
                    Spacer()
                    if !isInputActive {
                        if songs != nil {
                            Button {
                                showPlayView.toggle()
                            } label: {
                                Image(systemName: "play")
                                    .padding(13.5)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.blue)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(.blue, lineWidth: 2.5)
                                    }
                            }
                            .showPlayViewTip()
                            Button {
                                songDetailViewModel.showNotesView = true
                            } label: {
                                FAText(iconName: "book", size: 18)
                                    .modifier(NavBarButtonViewModifier())
                                    .overlay {
                                        // Show a badge when notes are present
                                        if notesViewModel.notes != "" {
                                            Circle()
                                                .frame(width: 11, height: 11)
                                                .foregroundColor(.blue)
                                                .offset(x: 17, y: -18)
                                        }
                                    }
                            }
                            .sheet(isPresented: $songDetailViewModel.showNotesView) {
                                NotesView(song: song)
                            }
                            // Fetch ellipsis/actions button from view model to cut down on file size
                            songDetailViewModel.optionsButton(song, lyrics: lyrics, isSongFromFolder: isSongFromFolder)
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
                                    recentlyDeletedViewModel.deleteSong(song: restoreSong!)
                                    presMode.wrappedValue.dismiss()
                                }
                                Button("Cancel", role: .cancel) { }
                            } message: {
                                Text("Are you sure you want to permanently delete \"\(restoreSong!.title)\"?")
                            }
                        }
                    } else {
                        Button(action: {
                            isInputActive = false
                        }, label: {
                            Text("Done")
                                .padding(14)
                                .font(.body.weight(.semibold))
                                .background(Material.regular)
                                .foregroundColor(.primary)
                                .clipShape(Capsule())
                        })
                    }
                }
                .padding(.top, 8)
                .padding([.horizontal, .bottom])
            }
            Divider()
            ZStack {
                // Check if there are any joined users
                let showJoinedUsers = joinedUsers?.isEmpty ?? true
                
                // Do not allow text editing if the song is read-only or in RecentlyDeleted
                TextEditor(text: songs == nil || (song.readOnly ?? false) ? .constant(lyrics) : $lyrics)
                    .multilineTextAlignment(alignment)
                    .font(.system(size: CGFloat(fontSize), weight: weight))
                    .lineSpacing(lineSpacing)
                    .focused($isInputActive)
                    .introspect(.textEditor, on: .iOS(.v14, .v15, .v16, .v17, .v18)) { textEditor in
                        // Add padding to insides of TextEditor
                        textEditor.textContainerInset = UIEdgeInsets(top: !showJoinedUsers ? 70 : 12, left: 12, bottom: 70, right: 12)
                        
                        // Get selected words to fetch rhymes, synonyms, etc.
                        if let textRange = textEditor.selectedTextRange {
                            DispatchQueue.main.async {
                                songDetailViewModel.selectedText = textEditor.text(in: textRange) ?? ""
                            }
                        }
                    }
                if restoreSong == nil {
                    // Add black "shadow" to avoid element conflicts
                    Color.black
                        .mask(LinearGradient(
                            gradient: Gradient(colors: [Color.black, Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(height: 95)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .opacity(!showJoinedUsers ? 1 : 0)
                        .allowsHitTesting(false)
                    VStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                if let joinedUsers = joinedUsers, !showJoinedUsers {
                                    ForEach(joinedUsers, id: \.id) { user in
                                        Button {
                                            selectedUser = user
                                            showUserPopover = true
                                        } label: {
                                            UserPopoverRowView(user: user, song: song)
                                        }
                                    }
                                }
                            }
                            .padding(10)
                        }
                        .frame(height: 70)
                        Spacer()
                        // Only show the text style options when song is not read-only
                        if !songDetailViewModel.readOnly(song) {
                            HStack {
                                Spacer()
                                SongDetailMenuView(value: $fontSize, weight: $weight, lineSpacing: $lineSpacing, alignment: $alignment, song: song)
                                    .padding(12)
                                    .background {
                                        // Add shadow to avoid element conflicts
                                        VisualEffectBlur(blurStyle: .dark)
                                            .blur(radius: 20)
                                    }
                            }
                        }
                    }
                } else {
                    if lyrics.isEmpty {
                        FullscreenMessage(imageName: "circle.slash", title: "There aren't any lyrics for this song.", spaceNavbar: true)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .frame(maxHeight: .infinity)
                    }
                }
            }
            Divider()
            // Don't show dictionary options when the user is editing, no word is selected, or the song is in recently deleted
            if restoreSong == nil {
                if isInputActive && !songDetailViewModel.selectedText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button {
                                fetchDatamuse(for: .rhyme)
                            } label: {
                                Text("Rhymes for \"\(songDetailViewModel.selectedText)\"")
                                    .modifier(SongDetailViewModel.DatamuseRowViewModifier())
                            }
                            Button {
                                fetchDatamuse(for: .synonymn)
                            } label: {
                                Text("Synonyms for \"\(songDetailViewModel.selectedText)\"")
                                    .modifier(SongDetailViewModel.DatamuseRowViewModifier())
                            }
                            Button {
                                fetchDatamuse(for: .antonymn)
                            } label: {
                                Text("Antonyms for \"\(songDetailViewModel.selectedText)\"")
                                    .modifier(SongDetailViewModel.DatamuseRowViewModifier())
                            }
                            Button {
                                fetchDatamuse(for: .related)
                            } label: {
                                Text("Words related to \"\(songDetailViewModel.selectedText)\"")
                                    .modifier(SongDetailViewModel.DatamuseRowViewModifier())
                            }
                            Button {
                                fetchDatamuse(for: .startsWith)
                            } label: {
                                Text("Words starting with \"\(songDetailViewModel.selectedText)\"")
                                    .modifier(SongDetailViewModel.DatamuseRowViewModifier())
                            }
                        }
                        .padding(12)
                    }
                } else {
                    VStack(spacing: 14) {
                        if #available(iOS 17, *) {
                            TipView(VariationsTip())
                                .tipViewStyle(LiveLyricsTipStyle())
                        }
                        if !isInputActive, let demoAttachments = song.demoAttachments {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(demoAttachments, id: \.self) { attachment in
                                        let demo = songViewModel.getDemo(from: attachment)
                                        
                                        Button {
                                            // Check if URL is valid before opening, and show an error if not
                                            guard let url = URL(string: attachment) else {
                                                activeAlert = .error
                                                errorMessage = NSLocalizedString("url_cant_be_opened", comment: "")
                                                return
                                            }
                                            
                                            openURL(url)
                                        } label: {
                                            HStack(spacing: 8) {
                                                songViewModel.getDemoIcon(from: demo.icon)
                                                Text(demo.title)
                                                    .lineLimit(1)
                                            }
                                            .foregroundColor(demo.color)
                                            .modifier(SongDetailViewModel.DatamuseRowViewModifier())
                                            .onLongPressGesture(minimumDuration: 1, maximumDistance: 10) {
                                                // Open a edit view when the user long presses a demo
                                                songDetailViewModel.showEditView = true
                                                songDetailViewModel.demoToEdit = demo
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.horizontal, -16)
                        }
                        HStack {
                            // Don't push the word count right when there are song variations
                            if !getShowVariationCondition() {
                                Spacer()
                            }
                            // Don't show word count if it's disabled in the user's settings
                            if wordCountBool {
                                Group {
                                    if wordCountStyle == "Words" {
                                        Text("\(wordCount) \((wordCount == 1) ? "Word" : "Words")")
                                    } else if wordCountStyle == "Characters" {
                                        Text("\(characterCount) \((characterCount == 1) ? "Character" : "Characters")")
                                    } else if wordCountStyle == "Spaces" {
                                        Text("\(spaceCount) \((spaceCount == 1) ? "Space" : "Spaces")")
                                    } else if wordCountStyle == "Paragraphs" {
                                        Text("\(paragraphCount) \((paragraphCount == 1) ? "Paragraph" : "Paragraphs")")
                                    }
                                }
                                .foregroundColor(.primary)
                                .font(.system(size: 16).weight(.semibold))
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
                                                        Label("Main", systemImage: selectedVariation == nil ? "checkmark" : "")
                                                    }
                                                    Divider()
                                                }
                                                // Show default variation if user is the song owner or if the user explicity or implicitly allowed it for shared users
                                                if (song.variations ?? []).isEmpty {
                                                    `default`
                                                } else {
                                                    if song.uid == songDetailViewModel.uid() {
                                                        `default`
                                                    } else if song.uid != songDetailViewModel.uid() && songVariations.contains(where: { $0.title == SongVariation.defaultId }) {
                                                        `default`
                                                    }
                                                }
                                                ForEach(songVariations, id: \.id) { variation in
                                                    // The default variation is identified by its unique title, so don't show it in the list
                                                    if variation.title != SongVariation.defaultId {
                                                        Button {
                                                            self.selectedVariation = variation
                                                            self.lyrics = variation.lyrics
                                                        } label: {
                                                            Label(variation.title, systemImage: (variation.id ?? "" == selectedVariation?.id ?? "") ? "checkmark" : "")
                                                        }
                                                    }
                                                }
                                                // Only show "new" and "manage" buttons when the song is not read-only and all variations are allowed
                                                if !songDetailViewModel.readOnly(song) {
                                                    if song.uid == songDetailViewModel.uid() || (song.variations ?? []).isEmpty {
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
                                            }
                                        } label: {
                                            HStack(spacing: 5) {
                                                if let variation = selectedVariation {
                                                    Text(variation.title)
                                                } else {
                                                    Text("Main")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            // Don't push elements left unless the word count and variation picker are absent
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
        }
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert, content: {
            // Check which alert is being displayed
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
            // FIXME: why is this property being check by a local variable?
            // Check if the user has enabled the word counter or not
            wordCountBool = viewModel.currentUser?.wordCount ?? true
            songViewModel.fetchSongVariations(song: song) { variations in
                // Check if there are any variations
                if let variationIds = song.variations, !variationIds.isEmpty {
                    // Initialize a variable to assign parsed variations to
                    var parsedVariations = [SongVariation]()
                    
                    // Default variation is allowed, add it to the array
                    if variationIds.contains(where: { $0 == SongVariation.defaultId }) || variationIds.isEmpty {
                        parsedVariations.append(SongVariation(title: SongVariation.defaultId, lyrics: "", songUid: "", songId: ""))
                    }
                    
                    let filteredVariations = variations.filter { variation in
                        // Make sure the variation is allowed, otherwise remove it
                        if let variationId = variation.id {
                            return variationIds.contains(variationId)
                        }
                        return false
                    }
                    parsedVariations.append(contentsOf: filteredVariations)
                    
                    // Set the inital lyrics
                    if let firstVariation = filteredVariations.first {
                        // The default variation is not included, so set the first variation
                        if !variationIds.contains(SongVariation.defaultId) {
                            selectedVariation = firstVariation
                            // Only set the lyrics if the user hasn't started editing
                            if !isInputActive {
                                self.lyrics = firstVariation.lyrics
                            }
                        }
                    } else {
                        // The default lyrics are allowed, set them as the inital lyrics
                        if !isInputActive {
                            self.lyrics = song.lyrics
                        }
                    }
                    
                    self.songVariations = parsedVariations
                } else {
                    // No restrictions are set, allow all variations
                    self.songVariations = variations
                }
            }
            songViewModel.fetchSong(listen: true, forUser: song.uid, song.id!) { song in
                // Save shared song properties to reassign
                let readOnly = self.song.readOnly
                let variations = self.song.variations
                let performanceMode = self.song.performanceMode
                
                if let song = song {
                    // Assignment overwrites sharedSong properties, so reassign them
                    self.song = song
                    self.song.readOnly = readOnly
                    self.song.variations = variations
                    self.song.performanceMode = performanceMode
                    
                    self.title = song.title
                    // Don't set fetched lyrics if the user is editing
                    if !isInputActive {
                        if selectedVariation == nil {
                            self.lyrics = song.lyrics
                        }
                    }
                    self.key = {
                        // Return "Not Set" if the key has not been set
                        if let key = song.key, !key.isEmpty {
                            return key
                        } else {
                            return NSLocalizedString("not_set", comment: "")
                        }
                    }()
                    self.artist = song.artist ?? ""
                    self.duration = song.duration ?? ""
                    self.tags = song.tags ?? []
                    self.weight = songDetailViewModel.getWeight(weight: Int(song.weight ?? 0))
                    self.alignment = songDetailViewModel.getAlignment(alignment: Int(song.alignment ?? 0))
                    self.fontSize = song.size ?? 18
                    self.lineSpacing = song.lineSpacing ?? 1
                    if joinedUsers == nil {
                        // Set the joinedUsersStrings var based on media type
                        if let folder = folder, folder.id! != songDetailViewModel.uid() {
                            self.joinedUsersStrings = folder.joinedUsers ?? []
                        } else {
                            self.joinedUsersStrings = song.joinedUsers ?? []
                        }
                        // User's id is not in the song, the user has been removed from the song
                        if !joinedUsersStrings.contains(where: { $0 == songDetailViewModel.uid() }) && song.uid != songDetailViewModel.uid() {
                            showAlert = true
                            activeAlert = .kickedOut
                        } else {
                            fetchUsers()
                        }
                    }
                }
            } regCompletion: { reg in
                // Assign a registration listener
                self.fetchListener = reg
            }
            checkForUpdatedLyrics()
            // Start a notes event listener
            notesViewModel.fetchNotes(song: song)
            // Do not allow device to fall asleep
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            // Deinitalize timers and registration listeners
            updatedLyricsTimer?.invalidate()
            updatedLyricsTimer = nil
            fetchListener?.remove()
            // Allow device to fall asleep
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .bottomSheet(isPresented: $showUserPopover, detents: [.medium()]) {
            if let folder = mainViewModel.selectedFolder, mainViewModel.folderSongs.contains(where: { $0.id! == song.id! }) {
                UserPopover(joinedUsers: $joinedUsers, selectedUser: $selectedUser, song: song, folder: folder, isSongFromFolder: isSongFromFolder)
            } else {
                UserPopover(joinedUsers: $joinedUsers, selectedUser: $selectedUser, song: song, folder: nil, isSongFromFolder: isSongFromFolder)
            }
        }
        .bottomSheet(isPresented: $showDatamuseSheet, detents: [.medium()]) {
            DatamuseWordDetailView(type: wordType)
        }
        .confirmationDialog("Delete Song", isPresented: $songDetailViewModel.showDeleteSheet) {
            Button("Delete", role: .destructive) {
                self.songViewModel.moveSongToRecentlyDeleted(song)
                self.presMode.wrappedValue.dismiss()
            }
            if let folder = folder {
                Button("Remove from Folder") {
                    // Remove the song from the provided folder
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
        .confirmationDialog("Leave Song", isPresented: $songDetailViewModel.showLeaveSheet) {
            Button("Leave", role: .destructive) {
                // If song is part of a shared folder, leave the folder
                if let folder = mainViewModel.selectedFolder, mainViewModel.folderSongs.contains(where: { $0.id ?? "" == song.id ?? "" }) {
                    self.mainViewModel.leaveCollabFolder(folder: folder)
                } else {
                    self.songViewModel.leaveSong(song: song)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            // If the song is from a folder, warn the user that the folder will be left
            Text("Are you sure you want to leave \"\(title)\"? You will lose access immediately. " + (isSongFromFolder ? NSLocalizedString("songs_parent_will_be_left", comment: "") : ""))
        }
        .sheet(isPresented: $songDetailViewModel.showShareSheet) {
            ShareView(isDisplayed: $songDetailViewModel.showShareSheet, song: song)
        }
        .sheet(isPresented: $songDetailViewModel.showEditView) {
            SongEditView(song: song, isDisplayed: $songDetailViewModel.showEditView, title: $title, key: $key, artist: $artist, duration: $duration)
        }
        .sheet(isPresented: $songDetailViewModel.showMoveView) {
            SongMoveView(song: song, showProfileView: $songDetailViewModel.showMoveView, songTitle: song.title)
        }
        .sheet(isPresented: $showNewVariationView, onDismiss: {
            // When a new variation is created, switch the lyrics to it
            if let index = songVariations.firstIndex(where: { $0.id == createdVariationId }) {
                self.selectedVariation = songVariations[index]
                self.lyrics = songVariations[index].lyrics
            }
        }) {
            NewSongVariationView(isDisplayed: $showNewVariationView, createdId: $createdVariationId, song: song)
        }
        .sheet(isPresented: $songDetailViewModel.showTagSheet) {
            let tags: [TagSelectionEnum] = tags.compactMap { TagSelectionEnum(rawValue: $0) }
            
            SongTagView(isPresented: $songDetailViewModel.showTagSheet, tagsToUpdate: $tags, tags: tags, song: song)
        }
        .sheet(isPresented: $showVariationsManagementSheet) {
            SongVariationManageView(song: song, isDisplayed: $showVariationsManagementSheet, lyrics: $lyrics, selectedVariation: $selectedVariation, songVariations: $songVariations)
        }
        .fullScreenCover(isPresented: $showPlayView) {
            PlayView(song: song, size: fontSize, weight: weight, lineSpacing: lineSpacing, alignment: alignment, key: key, title: title, lyrics: lyrics, duration: $duration, bpm: $bpm, bpb: $bpb, performanceMode: $performanceMode, songs: songs ?? [], dismiss: $showPlayView)
        }
        .onChange(of: isInputActive) { isInputActive in
            // Show and hide the list of joined users when the user focuses and unfocuses the keyboard
            withAnimation(.bouncy(duration: 0.4)) {
                if isInputActive {
                    showJoinedUsers = false
                } else {
                    showJoinedUsers = true
                }
            }
        }
    }
}
