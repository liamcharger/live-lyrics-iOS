//
//  NewSongView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import SwiftUI

struct NewSongView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @State var title = ""
    @State var artist = ""
    @State var key = ""
    @State var lyrics = ""
    @State var errorMessage = ""
    
    @State var view2 = false
    @State var showError = false
    @State var showInfo = false
    @State var canDismissProgrammatically = false
    @State var showProgressButton = false
    
    @Binding var isDisplayed: Bool
    
    @FocusState var isTitleFocused: Bool
    @FocusState var isLyricsFocused: Bool
    
    func createSong() {
        showProgressButton = true
        
        let dismiss = {
            canDismissProgrammatically = true
            view2 = false
        }
        
        if NetworkManager.shared.getNetworkState() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
        
        songViewModel.createSong(lyrics: lyrics, title: title, artist: artist, key: key) { success, errorMessage in
            if success {
                dismiss()
            } else {
                self.errorMessage = errorMessage
                showError = true
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Enter some details for your song.")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                CloseButton {
                    isDisplayed = false
                }
            }
            .padding()
            Divider()
            ScrollView {
                VStack {
                    CustomTextField(text: $title, placeholder: NSLocalizedString("title", comment: ""), image: "character.cursor.ibeam")
                        .focused($isTitleFocused)
                    CustomTextField(text: $artist, placeholder: NSLocalizedString("artist_optional", comment: ""), image: "person")
                    CustomTextField(text: $key, placeholder: NSLocalizedString("key_optional", comment: ""), image: "arrow.up.arrow.down")
                }
                .padding()
            }
            Divider()
            LiveLyricsButton("Continue", showProgressIndicator: .constant(false), action: { view2 = true })
                .padding()
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .sheet(isPresented: $view2) {
                    nextView
                }
                .onChange(of: view2) { newValue in
                    if !newValue {
                        if canDismissProgrammatically {
                            isDisplayed = false
                        }
                    }
                }
        }
        .onAppear {
            isTitleFocused = true
        }
    }
    
    var nextView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Enter the lyrics for your song.")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                CloseButton {
                    view2 = false
                }
            }
            .padding()
            Divider()
            TextEditor(text: $lyrics)
                .padding(.horizontal)
                .focused($isLyricsFocused)
            Divider()
            LiveLyricsButton("Continue", showProgressIndicator: $showProgressButton, action: {
                if lyrics.isEmpty {
                    showInfo.toggle()
                } else {
                    createSong()
                }
            })
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert("Your song doesn't have any lyrics. Continue anyway?", isPresented: $showInfo, actions: {
            Button(action: createSong, label: {Text("Continue")})
            Button(role: .cancel, action: {}, label: {Text("Cancel")})
        })
        .onAppear {
            isLyricsFocused = true
        }
    }
}
