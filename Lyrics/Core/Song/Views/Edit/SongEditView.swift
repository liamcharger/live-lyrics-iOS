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
    @Environment(\.presentationMode) var presMode
    
    let song: Song
    
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
    @State var showNotesView = false
    
    @FocusState var isFocused: Bool
    
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isDisplayed = false
        }
        songViewModel.updateSong(song, title: stateTitle, key: stateKey, artist: stateArtist, duration: stateDuration) { success, errorMessage in
            if success {
//                self.isDisplayed = false
            } else {
                self.showError = true
                self.errorMessage = errorMessage
            }
        }
    }
    func isInvalidFormat(_ duration: String) -> Bool {
        let pattern = "^\\d+:\\d+\\d+$"
        return !duration.isEmpty && !(duration.range(of: pattern, options: .regularExpression) != nil)
    }
    
    init(song: Song, isDisplayed: Binding<Bool>, title: Binding<String>, key: Binding<String>, artist: Binding<String>, duration: Binding<String>) {
        self.song = song
        self._isDisplayed = isDisplayed
        self._title = title
        self._key = key
        self._artist = artist
        self._duration = duration
        
        self._stateTitle = State(initialValue: title.wrappedValue)
        self._stateArtist = State(initialValue: artist.wrappedValue == "Not Set" ? "": artist.wrappedValue)
        self._stateKey = State(initialValue: key.wrappedValue == "Not Set" ? "": key.wrappedValue)
        self._stateDuration = State(initialValue: duration.wrappedValue == "Not Set" ? "": duration.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Song")
                    .font(.title.weight(.bold))
                Spacer()
                SheetCloseButton(isPresented: $isDisplayed)
            }
            .padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading) {
                    CustomTextField(text: $stateTitle, placeholder: "Title")
                        .focused($isFocused)
                    CustomTextField(text: $stateKey, placeholder: "Key")
                    CustomTextField(text: $stateArtist, placeholder: "Artist")
                    CustomTextField(text: $stateDuration, placeholder: "Duration")
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
                Button(action: update) {
                    Text(NSLocalizedString("save", comment: "Save"))
                        .frame(maxWidth: .infinity)
                        .modifier(NavButtonViewModifier())
                }
                .opacity(isEmpty ? 0.5 : 1.0)
                .disabled(isEmpty)
            }
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
        .onAppear {
            isFocused = true
        }
    }
}
