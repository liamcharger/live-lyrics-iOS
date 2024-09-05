//
//  SongEditView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/18/23.
//

import SwiftUI
import Combine

struct SongEditView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var mainViewModel = MainViewModel.shared
    
    @Environment(\.presentationMode) var presMode
    @Environment(\.openURL) var openURL
    
    let song: Song
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @Binding var isDisplayed: Bool
    @Binding var title: String
    @Binding var key: String
    @Binding var duration: String
    @Binding var artist: String
    
    @State var errorMessage = ""
    @State var stateArtist = ""
    @State var stateKey = ""
    @State var stateTitle = ""
    @State var stateDuration = ""
    
    @State var showError = false
    
    var isEmpty: Bool {
        let isTitleEmpty = title.trimmingCharacters(in: .whitespaces).isEmpty
        let isDurationInvalid = !stateDuration.isEmpty && isInvalidFormat(stateDuration)
        
        return isTitleEmpty || isDurationInvalid
    }
    func update() {
        self.title = stateTitle
        self.key = stateKey
        self.artist = stateArtist
        self.duration = stateDuration
        songViewModel.updateSong(song, title: stateTitle, key: stateKey, artist: stateArtist, duration: stateDuration) { success, errorMessage in
            if !success {
                self.showError = true
                self.errorMessage = errorMessage
            }
        }
        dismiss()
    }
    func isInvalidFormat(_ duration: String) -> Bool {
        let pattern = "^\\d+:\\d+\\d+$"
        return !duration.isEmpty && !(duration.range(of: pattern, options: .regularExpression) != nil)
    }
    func dismiss() {
        if let folder = mainViewModel.selectedFolder {
            mainViewModel.fetchSongs(folder)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isDisplayed = false
        }
    }
    
    init(song: Song, isDisplayed: Binding<Bool>, title: Binding<String>, key: Binding<String>, artist: Binding<String>, duration: Binding<String>) {
        self.song = song
        self._isDisplayed = isDisplayed
        self._title = title
        self._key = key
        self._artist = artist
        self._duration = duration
        
        self._stateTitle = State(initialValue: title.wrappedValue)
        self._stateArtist = State(initialValue: artist.wrappedValue == NSLocalizedString("not_set", comment: "") ? "": artist.wrappedValue)
        self._stateKey = State(initialValue: key.wrappedValue == NSLocalizedString("not_set", comment: "") ? "": key.wrappedValue)
        self._stateDuration = State(initialValue: duration.wrappedValue == NSLocalizedString("not_set", comment: "") ? "": duration.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Song")
                    .font(.title.weight(.bold))
                Spacer()
                SheetCloseButton {
                    presMode.wrappedValue.dismiss()
                }
            }
            .padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack {
                        CustomTextField(text: $stateTitle, placeholder: NSLocalizedString("title", comment: ""))
                        CustomTextField(text: $stateKey, placeholder: NSLocalizedString("Key", comment: ""))
                        CustomTextField(text: $stateArtist, placeholder: NSLocalizedString("Artist", comment: ""))
                        CustomTextField(text: $stateDuration, placeholder: NSLocalizedString("duration", comment: ""))
                    }
                    VStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text("Demo Attachments".uppercased())
                                    .font(.system(size: 16).weight(.bold))
                                Image(systemName: "info.circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                Spacer()
                                Button {
                                    
                                } label: {
                                    Image(systemName: "plus")
                                        .padding(10)
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        if let demoAttachments = song.demoAttachments {
                            LazyVGrid(columns: columns) {
                                ForEach(demoAttachments, id: \.self) { attachment in
                                    let provider = songViewModel.getProvider(from: attachment)
                                    
                                    Button {
                                        guard let url = URL(string: attachment) else { return }
                                        
                                        openURL(url)
                                    } label: {
                                        ContentRowView(NSLocalizedString(provider.title, comment: ""), icon: provider.icon, color: provider.color)
                                    }
                                }
                            }
                        }
                    }
                    if isInvalidFormat(stateDuration) {
                        Group {
                            Text("The duration is not formatted correctly. Correct formatting, e.g., ") +
                            Text("2:33").font(.body.weight(.bold)) +
                            Text(".")
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                    }
                }
                .padding()
            }
            Divider()
            VStack(spacing: 16) {
                Text("These settings are not specific to song variations.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.gray)
                LiveLyricsButton("Save", action: update)
                    .opacity(isEmpty ? 0.5 : 1.0)
                    .disabled(isEmpty)
            }
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
    }
}
