//
//  SongEditView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/18/23.
//

import SwiftUI

struct SongEditView: View {
    // Environment vars
    @ObservedObject var viewModel = SongViewModel()
    @Environment(\.presentationMode) var presMode
    
    let song: Song
    
    // Binding vars
    @Binding var showProfileView: Bool
    @Binding var title: String
    @Binding var key: String
    @Binding var duration: String
    @Binding var artist: String
    
    // State vars
    @State var errorMessage = ""
    @State var stateArtist = ""
    @State var stateKey = ""
    @State var stateTitle = ""
    @State var stateDuration = ""
    
    @State var showError = false
    @State var showNotesView = false
    
    // Standard vars
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // Functions
    func update() {
        viewModel.updateKey(song, key: stateKey) { success in
            if success {
                self.key = stateKey
                showProfileView = false
            } else {
                showError.toggle()
            }
        } completionString: { string in
            errorMessage = string
        }
        viewModel.updateArtist(song, artist: stateArtist) { success in
            if success {
                self.artist = stateArtist
                self.showProfileView = false
            } else {
                showError.toggle()
            }
        } completionString: { string in
            errorMessage = string
        }
        viewModel.updateDuration(song, duration: stateDuration) { success in
            if success {
                self.duration = stateDuration
                self.showProfileView = false
            } else {
                showError.toggle()
            }
        } completionString: { string in
            errorMessage = string
        }
        viewModel.updateTitle(song, title: stateTitle) { success in
            if success {
                self.title = stateTitle
                self.showProfileView = false
            } else {
                showError.toggle()
            }
        } completionString: { string in
            errorMessage = string
        }
    }
    
    init(song: Song, showProfileView: Binding<Bool>, title: Binding<String>, key: Binding<String>, artist: Binding<String>, duration: Binding<String>) {
        self.song = song
        self._showProfileView = showProfileView
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
                SheetCloseButton(isPresented: $showProfileView)
            }
            .padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading) {
                    CustomTextField(text: $stateTitle, placeholder: "Title")
                    CustomTextField(text: $stateKey, placeholder: "Key")
                    CustomTextField(text: $stateArtist, placeholder: "Artist")
                    CustomTextField(text: $stateDuration, placeholder: "Duration")
                }
                .padding(.top)
                .padding(.horizontal)
            }
            Divider()
            Button(action: update, label: {
                HStack {
                    Spacer()
                    Text(NSLocalizedString("save", comment: "Save"))
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
            })
            .opacity(isEmpty ? 0.5 : 1.0)
            .disabled(isEmpty)
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
    }
}
