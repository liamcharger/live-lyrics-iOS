//
//  SongDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import SwiftUI
import BottomSheet

struct SongDetailView: View {
    // State vars
    @State var song: Song
    @State var folder: Folder?
    @State var restoreSong: RecentlyDeletedSong?
    
    @State private var currentIndex = 0
    @State private var value: Int
    @State private var lineSpacing: Double
    @State private var design: Font.Design
    @State private var weight: Font.Weight
    @State private var alignment: TextAlignment
    
    @State var lyrics = ""
    @State var key = ""
    @State var title = ""
    @State var artist = ""
    @State var errorMessage = ""
    @State var isChecked = ""
    @State var autoscrollDuration = ""
    @State var duration = ""
    
    @State var songIds: [String]?
    
    @State var showEditView = false
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
    
    // ObservedObject vars
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @ObservedObject var songSettingsViewModel = SongSettingsViewModel()
    @EnvironmentObject var viewModel: AuthViewModel
    
    // Environment vars
    @Environment(\.presentationMode) var presMode
    
    // FocusState vars
    @FocusState var isInputActive: Bool
    
    // Let vars
    let isDefaultSong: Bool
    let albumData: AlbumDetailsResponse?
    
    // App Storage vars
    @AppStorage(firstTimeAlertKey) private var firstTimeAlertShown: Bool = false
    
    // Standard vars
    var songs: [Song]?
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
    func saveSongToMySongs(song: Song) {
        songViewModel.addSongToMySongs(id: song.id ?? UUID().uuidString, lyrics: song.lyrics, title: song.title, artist: albumData == nil ? "" : removeFeatAndAfter(from: albumData?.message.body.album.artistName ?? ""), timestamp: Date.now, key: song.key, bpm: song.bpm) { success, errorMessage in
            if success {
                self.showAlert = true
            } else {
                self.errorMessage = errorMessage
                self.showError = true
            }
        }
    }
    
    // Initialization
    init(song: Song, songs: [Song]?, restoreSong: RecentlyDeletedSong?, wordCountStyle: String, isDefaultSong: Bool, albumData: AlbumDetailsResponse?, folder: Folder?) {
        self.songs = songs
        self.isDefaultSong = isDefaultSong
        self._isChecked = State(initialValue: wordCountStyle)
        self._restoreSong = State(initialValue: restoreSong)
        self._value = State(initialValue: song.size ?? 18)
        self._lineSpacing = State(initialValue: song.lineSpacing ?? 1.0)
        
        switch Int(song.design ?? 0) {
        case 0:
            self._design = State(initialValue: .default)
        case 1:
            self._design = State(initialValue: .monospaced)
        case 2:
            self._design = State(initialValue: .rounded)
        case 3:
            self._design = State(initialValue: .serif)
        default:
            self._design = State(initialValue: .default)
        }
        
        switch Int(song.weight ?? 0) {
        case 0:
            self._weight = State(initialValue: .regular)
        case 1:
            self._weight = State(initialValue: .black)
        case 2:
            self._weight = State(initialValue: .bold)
        case 3:
            self._weight = State(initialValue: .heavy)
        case 4:
            self._weight = State(initialValue: .light)
        case 5:
            self._weight = State(initialValue: .medium)
        case 6:
            self._weight = State(initialValue: .regular)
        case 7:
            self._weight = State(initialValue: .semibold)
        case 8:
            self._weight = State(initialValue: .thin)
        default:
            self._weight = State(initialValue: .ultraLight)
        }
        
        switch Int(song.alignment ?? 0) {
        case 0:
            self._alignment = State(initialValue: .leading)
        case 1:
            self._alignment = State(initialValue: .leading)
        case 2:
            self._alignment = State(initialValue: .center)
        case 3:
            self._alignment = State(initialValue: .trailing)
        default:
            self._alignment = State(initialValue: .leading)
        }
        
        self._folder = State(initialValue: folder)
        self._song = State(initialValue: song)
        self._lyrics = State(initialValue: song.lyrics)
        self._title = State(initialValue: song.title)
        self._currentIndex = State(initialValue: song.order ?? 0)
        self._key = State(initialValue: song.key == "" ? "Not Set" : song.key ?? "Not Set")
        self._artist = State(initialValue: song.artist == "" ? "Not Set" : song.artist ?? "Not Set")
        self._duration = State(initialValue: song.duration ?? "")
        self.albumData = albumData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack {
                HStack {
                    Button(action: {presMode.wrappedValue.dismiss()}, label: {
                        Image(systemName: "chevron.left")
                            .padding()
                            .font(.body.weight(.semibold))
                            .background(Material.regular)
                            .foregroundColor(.primary)
                            .clipShape(Circle())
                    })
                    Spacer()
                    if !isInputActive {
                        if songs != nil {
                                if #available(iOS 17.0, *) {
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
                                    .showTip()
                                } else {
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
                            Button(action: {showNotesView.toggle()}, label: {
                                Image(systemName: "doc.text")
                                    .modifier(NavBarButtonViewModifier())
                            })
                            .sheet(isPresented: $showNotesView) {
                                NotesView(song: song)
                            }
                            
                            menu
                            
                            settings
                        } else {
                            if isDefaultSong {
                                Button {
                                    showFullScreenView.toggle()
                                } label: {
                                    Image(systemName: "play")
                                        .modifier(NavBarButtonViewModifier())
                                }
                                .showTip()
                                Button(action: {
                                    saveSongToMySongs(song: song)
                                }) {
                                    Image(systemName: "plus")
                                        .modifier(NavBarButtonViewModifier())
                                }
                                .alert(isPresented: $showSongRepititionAlert) {
                                    Alert(
                                        title: Text("It looks like this song is already in your library."),
                                        message: Text("Do you want to add it anyway?"),
                                        primaryButton: .default(Text(NSLocalizedString("continue", comment: "Continue"))) {
                                            if let songId = song.id {
                                                songViewModel.addSongToMySongs(id: songId, lyrics: song.lyrics, title: song.title, artist: albumData == nil ? song.artist : albumData?.message.body.album.artistName, timestamp: Date.now, key: song.key, bpm: song.bpm) { success, errorMessage in
                                                    if success {
                                                        self.showSongRepititionAlert = false
                                                        self.showAlert = true
                                                    } else {
                                                        self.errorMessage = errorMessage
                                                        self.showError = true
                                                    }
                                                }
                                            }
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            } else {
                                Button(action: {
                                    if restoreSong?.folderId == nil {
                                        mainViewModel.restoreSong(song: restoreSong!)
                                    } else {
                                        mainViewModel.restoreSongToFolder(song: restoreSong!)
                                    }
                                    presMode.wrappedValue.dismiss()
                                }, label: {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .modifier(NavBarButtonViewModifier())
                                })
                                Button(action: {
                                    self.showDeleteSheet.toggle()
                                }, label: {
                                    Image(systemName: "trash")
                                        .modifier(NavBarButtonViewModifier())
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
                        }
                    } else {
                        if songs != nil {
                            if viewModel.currentUser?.id == "HyeuTQD8PqfGWFzCIf242dFh0P83" {
                                Button(action: {showThesaurusView.toggle()}, label: {
                                    Image(systemName: "text.bubble")
                                        .modifier(NavBarButtonViewModifier())
                                })
                                .sheet(isPresented: $showThesaurusView) {
                                    ThesaurusView()
                                }
                            }
                        }
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
                .padding([.horizontal])
                .padding(.top, 10)
                HStack(alignment: .center, spacing: 8) {
                    Text(title)
                        .font(.system(size: 23).weight(.bold))
                        .lineLimit(1).truncationMode(.tail)
                    Spacer()
                    Text("Key: \(key == "" ? "Not Set" : key)").foregroundColor(Color.gray)
                    if let albumData = albumData {
                        Button {
                            showSongDataView.toggle()
                        } label: {
                            Image(systemName: "info.circle").imageScale(.large)
                        }
                        .bottomSheet(isPresented: $showSongDataView, detents: [.medium(), .large()], prefersGrabberVisible: true) {
                            SongDataView(albumData: albumData, song: song)
                        }
                    }
                }
                .padding(.top, 8)
                .padding([.horizontal, .bottom])
            }
            Divider()
            // MARK: TextEditor
            TextEditor(text: isDefaultSong || songs == nil ? .constant(lyrics) : $lyrics)
                .multilineTextAlignment(alignment)
                .onChange(of: lyrics, perform: { newLyrics in
                    mainViewModel.updateLyrics(song, lyrics: newLyrics)
                })
                .padding(.leading, 11)
                .font(.system(size: CGFloat(value), weight: weight, design: design))
                .lineSpacing(lineSpacing)
                .focused($isInputActive)
            // MARK: Bottom toolbar
            if songs != nil {
                if wordCountBool {
                    Divider()
                    HStack {
                        Spacer()
                        HStack {
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
                        .foregroundColor(Color("Color"))
                        .font(.system(size: 16).weight(.semibold))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if #available(iOS 17, *) {
                Task {
                    await PlayViewTip.numberOfTimesVisited.donate()
                }
            }
            self.songSettingsViewModel.fetchSong(songId: song.id ?? "") { song in
                if song.autoscrollDuration != nil || song.autoscrollDuration == "" {
                    self.autoscrollDuration = song.autoscrollDuration ?? ""
                } else if song.duration != nil {
                    self.autoscrollDuration = song.duration ?? ""
                }
            }
            wordCountBool = viewModel.currentUser?.wordCount ?? true
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .confirmationDialog("Delete Song", isPresented: $showDeleteSheet) {
            Button("Delete", role: .destructive) {
                print("Deleting song: \(song.title)")
                songViewModel.moveSongToRecentlyDeleted(song)
                mainViewModel.fetchSongs()
                presMode.wrappedValue.dismiss()
            }
            if let folder = folder {
                Button("Remove from Folder") {
                    songViewModel.moveSongToRecentlyDeleted(folder, song)
                    mainViewModel.fetchSongs(folder)
                    presMode.wrappedValue.dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(song.title)\"?")
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Success"), message: Text("The song was successfully added to your library."), dismissButton: .cancel(Text("Close"), action: {}))
        }
        .sheet(isPresented: $showEditView) {
            SongEditView(song: song, showProfileView: $showEditView, title: $title, key: $key, artist: $artist, duration: $duration)
        }
        .bottomSheet(isPresented: $showSettingsView, detents: [.medium(), .large()]) {
            SongSettingsView(song: song, autoscrollDuration: $autoscrollDuration, hasDeletedSong: $hasDeletedSong)
        }
        .fullScreenCover(isPresented: $showFullScreenView) {
            SongFullScreenView(song: song, size: value, design: design, weight: weight, lineSpacing: lineSpacing, alignment: alignment, key: key, title: title, lyrics: lyrics, duration: $autoscrollDuration, songs: isDefaultSong ? nil : songs!, dismiss: $showFullScreenView, hasDeletedSong: $hasDeletedSong)
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
            //            Button(action: {
            //                showSettingsView.toggle()
            //            }, label: {
            //                Label("More", systemImage: "ellipsis")
            //            })
            Button(role: .destructive, action: {
                showDeleteSheet.toggle()
            }, label: {
                Label("Delete", systemImage: "trash")
            })
        } label: {
            Image(systemName: "gear")
                .modifier(NavBarButtonViewModifier())
        }
    }
}
