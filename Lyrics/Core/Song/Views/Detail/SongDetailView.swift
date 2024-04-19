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

struct SongDetailView: View {
    @State var song: Song
    @State var folder: Folder?
    @State var restoreSong: RecentlyDeletedSong?
    @State var selectedVariation: SongVariation?
    
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
    @State var bpm = 120
    @State var bpb = 4
    @State var performanceMode = true
    @State var tags: [String] = []
    
    @State var songIds: [String]?
    @State var fullUsernameString = [String]()
    
    @State var showEditView = false
    @State var showTagSheet = false
    @State var showMoveView = false
    @State var showShareSheet = false
    @State var showSettingsView = false
    @State var wordCountBool = false
    @State var showDeleteSheet = false
    @State var showThesaurusView = false
    @State var showAutoScrollView = false
    @State var showNotesView = false
    @State var showFullScreenView = false
    @State var showSongDataView = false
    @State var showInfo = false
    @State var showAlert = false
    @State var showSongRepititionAlert = false
    @State var showPlayViewInfo = false
    @State var showError = false
    @State var hasDeletedSong = false
    @State var showNotesStatusIcon = false
    @State var showNewVariationView = false
    
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @ObservedObject var recentlyDeletedViewModel = RecentlyDeletedViewModel.shared
    @EnvironmentObject var viewModel: AuthViewModel
    @ObservedObject var notesViewModel: NotesViewModel
    
    @Environment(\.presentationMode) var presMode
    
    @FocusState var isInputActive: Bool
    
    var songs: [Song]?
    var songVariations: [SongVariation] = []
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
                                menu
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
                                    self.showDeleteSheet.toggle()
                                }, label: {
                                    FAText(iconName: "trash-can", size: 18)
                                        .padding()
                                        .font(.body.weight(.semibold))
                                        .background(Material.regular)
                                        .foregroundColor(.primary)
                                        .clipShape(Circle())
                                })
                                .confirmationDialog("Delete Song", isPresented: $showDeleteSheet) {
                                    Button("Delete", role: .destructive) {
                                        print("Deleting song: \(restoreSong!.title)")
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
                    if !currentEditorsTitle.isEmpty && !currentEditorsSubtitle.isEmpty {
                        VStack(alignment: .leading) {
                            Text(currentEditorsTitle)
                                .font(.body.weight(.semibold))
                            Text(currentEditorsSubtitle)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Material.regular)
                        .foregroundColor(.primary)
                        .cornerRadius(20)
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
                }
                .padding(.top, 8)
                .padding([.bottom, .horizontal])
            }
            Divider()
            TextEditor(text: songs == nil ? .constant(lyrics) : $lyrics)
                .multilineTextAlignment(alignment)
                .font(.system(size: CGFloat(value), weight: weight, design: design))
                .lineSpacing(lineSpacing)
                .focused($isInputActive)
                .padding(.leading, 11)
            Divider()
            HStack {
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
                Spacer()
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
                        ForEach(songVariations, id: \.id) { variation in
                            Button {
                                selectedVariation = variation
                            } label: {
                                Label(variation.title, systemImage: (variation.id ?? "" == selectedVariation?.id ?? "") ? "checkmark" : "")
                            }
                        }
                        Divider()
                        Button {
                            selectedVariation = nil
                        } label: {
                            Label("Default", systemImage: selectedVariation == nil ? "checkmark" : "")
                        }
                        Button {
                            showNewVariationView = true
                        } label: {
                            Label("Create New", systemImage: "plus")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Variations")
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                }
                if !wordCountBool {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            wordCountBool = viewModel.currentUser?.wordCount ?? true
            songViewModel.fetchSong(song.id ?? "") { song in
                self.title = song.title
                self.lyrics = song.lyrics
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
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                    if lyrics != lastUpdatedLyrics {
                        mainViewModel.updateLyrics(song, lyrics: lyrics)
                        lastUpdatedLyrics = lyrics
                    }
                }
            } regCompletion: { reg in
                self.fetchListener = reg
            }
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            fetchListener?.remove()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .confirmationDialog("Delete Song", isPresented: $showDeleteSheet) {
            Button("Delete", role: .destructive) {
                print("Deleting song: \(title)")
                songViewModel.moveSongToRecentlyDeleted(song)
                presMode.wrappedValue.dismiss()
            }
            if let folder = folder {
                Button("Remove from Folder") {
                    songViewModel.moveSongToRecentlyDeleted(folder, song)
                    presMode.wrappedValue.dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(title)\"?")
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
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
        .sheet(isPresented: $showNewVariationView) {
            NewSongVariationView(isDisplayed: $showNewVariationView)
        }
        .sheet(isPresented: $showTagSheet) {
            let tags: [TagSelectionEnum] = tags.compactMap { TagSelectionEnum(rawValue: $0) }
            SongTagView(isPresented: $showTagSheet, tagsToUpdate: $tags, tags: tags, song: song)
        }
        .fullScreenCover(isPresented: $showFullScreenView) {
            PlayView(song: song, size: value, design: design, weight: weight, lineSpacing: lineSpacing, alignment: alignment, key: key, title: title, lyrics: lyrics, duration: {
                if duration.isEmpty {
                    return .constant("")
                } else {
                    return $duration
                }
            }(), bpm: $bpm, bpb: $bpb, performanceMode: $performanceMode, songs: songs!, dismiss: $showFullScreenView, hasDeletedSong: $hasDeletedSong)
        }
        .onChange(of: hasDeletedSong, perform: { value in
            if value == true {
                presMode.wrappedValue.dismiss()
            }
        })
    }
    
    var menu: some View {
        Menu {
            Menu {
                Button(action: {
                    value = 18
                    songViewModel.updateTextProperties(song, size: 18)
                }, label: {
                    Text("Default")
                })
                Divider()
                Button(action: {
                    value = 12
                    songViewModel.updateTextProperties(song, size: 12)
                }, label: {
                    Text("12")
                })
                Button(action: {
                    value = 14
                    songViewModel.updateTextProperties(song, size: 14)
                }, label: {
                    Text("14")
                })
                Button(action: {
                    value = 16
                    songViewModel.updateTextProperties(song, size: 16)
                }, label: {
                    Text("16")
                })
                Button(action: {
                    value = 18
                    songViewModel.updateTextProperties(song, size: 18)
                }, label: {
                    Text("18")
                })
                Button(action: {
                    value = 20
                    songViewModel.updateTextProperties(song, size: 20)
                }, label: {
                    Text("20")
                })
                Button(action: {
                    value = 24
                    songViewModel.updateTextProperties(song, size: 24)
                }, label: {
                    Text("24")
                })
                Button(action: {
                    value = 28
                    songViewModel.updateTextProperties(song, size: 28)
                }, label: {
                    Text("28")
                })
                Button(action: {
                    value = 30
                    songViewModel.updateTextProperties(song, size: 30)
                }, label: {
                    Text("30")
                })
            } label: {
                Text("Font Size")
            }
            Menu {
                Button(action: {
                    design = .default
                    songViewModel.updateTextProperties(song, design: 0)
                }, label: {
                    Text("Default")
                })
                Divider()
                Button(action: {
                    design = .default
                    songViewModel.updateTextProperties(song, design: 0)}, label: {
                        Text("Regular")
                    })
                Button(action: {
                    design = .monospaced
                    songViewModel.updateTextProperties(song, design: 1)
                }, label: {
                    Text("Monospaced")
                })
                Button(action: {
                    design = .rounded
                    songViewModel.updateTextProperties(song, design: 2)
                }, label: {
                    Text("Rounded")
                })
                Button(action: {
                    design = .serif
                    songViewModel.updateTextProperties(song, design: 3)
                }, label: {
                    Text("Serif")
                })
            } label: {
                Text("Font Style")
            }
            Menu {
                Button(action: {
                    weight = .regular
                    songViewModel.updateTextProperties(song, weight: 0)
                }, label: {
                    Text("Default")
                })
                Divider()
                Button(action: {
                    weight = .black
                    songViewModel.updateTextProperties(song, weight: 1)
                }, label: {
                    Text("Black")
                })
                Button(action: {
                    songViewModel.updateTextProperties(song, weight: 2)
                    weight = .bold
                }, label: {
                    Text("Bold")
                })
                Button(action: {
                    weight = .heavy
                    songViewModel.updateTextProperties(song, weight: 3)
                }, label: {
                    Text("Heavy")
                })
                Button(action: {
                    weight = .light
                    songViewModel.updateTextProperties(song, weight: 4)
                }, label: {
                    Text("Light")
                })
                Button(action: {
                    weight = .medium
                    songViewModel.updateTextProperties(song, weight: 5)
                }, label: {
                    Text("Medium")
                })
                Button(action: {
                    weight = .regular
                    songViewModel.updateTextProperties(song, weight: 6)
                }, label: {
                    Text("Regular")
                })
                Button(action: {
                    weight = .semibold
                    songViewModel.updateTextProperties(song, weight: 7)
                }, label: {
                    Text("Semibold")
                })
                Button(action: {
                    weight = .thin
                    songViewModel.updateTextProperties(song, weight: 8)
                }, label: {
                    Text("Thin")
                })
                Button(action: {
                    weight = .ultraLight
                    songViewModel.updateTextProperties(song, weight: 0)
                }, label: {
                    Text("Ultra Light")
                })
            } label: {
                Text("Font Weight")
            }
            Menu {
                Button(action: {
                    lineSpacing = 1
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("Default")
                })
                Divider()
                Button(action: {
                    lineSpacing = 1
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("0.0")
                })
                Button(action: {
                    lineSpacing = 5
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("0.5")
                })
                Button(action: {
                    lineSpacing = 10
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("1.0")
                })
                Button(action: {
                    lineSpacing = 15
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("1.5")
                })
                Button(action: {
                    lineSpacing = 20
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("2.0")
                })
                Button(action: {
                    lineSpacing = 25
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("2.5")
                })
                Button(action: {
                    lineSpacing = 30
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("3.0")
                })
            } label: {
                Text("Line Spacing")
            }
            Menu {
                Button(action: {
                    alignment = .leading
                    songViewModel.updateTextProperties(song, alignment: 0)
                }, label: {
                    Text("Default")
                })
                Divider()
                Button(action: {
                    alignment = .leading
                    songViewModel.updateTextProperties(song, alignment: 0)
                }, label: {
                    Text("Left")
                })
                Button(action: {
                    alignment = .center
                    songViewModel.updateTextProperties(song, alignment: 1)
                }, label: {
                    Text("Center")
                })
                Button(action: {
                    alignment = .trailing
                    songViewModel.updateTextProperties(song, alignment: 2)
                }, label: {
                    Text("Right")
                })
            } label: {
                Text("Alignment")
            }
            Divider()
            Button {
                value = 18
                songViewModel.updateTextProperties(song, size: 18)
                
                design = .default
                songViewModel.updateTextProperties(song, design: 0)
                
                weight = .regular
                songViewModel.updateTextProperties(song, weight: 0)
                
                lineSpacing = 1
                songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                
                alignment = .leading
                songViewModel.updateTextProperties(song, alignment: 0)
            } label: {
                Text("Restore to Defaults")
            }
        } label: {
            Image(systemName: "textformat.size")
                .modifier(NavBarButtonViewModifier())
        }
    }
    var settings: some View {
        Menu {
            Button(action: {
                showEditView.toggle()
            }, label: {
                Label("Edit", systemImage: "pencil")
            })
            Button(action: {
                showShareSheet = true
            }, label: {
                Label("Share", systemImage: "square.and.arrow.up")
            })
            Button(action: {
                showMoveView.toggle()
            }, label: {
                Label("Move", systemImage: "folder")
            })
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
            } label: {
                Label("Copy", systemImage: "doc")
            }
            Button {
                showTagSheet = true
            } label: {
                Label("Tags", systemImage: "tag")
            }
            Button(role: .destructive, action: {
                showDeleteSheet.toggle()
            }, label: {
                Label("Delete", systemImage: "trash")
            })
        } label: {
            FAText(iconName: "ellipsis", size: 18)
                .modifier(NavBarButtonViewModifier())
        }
    }
}
