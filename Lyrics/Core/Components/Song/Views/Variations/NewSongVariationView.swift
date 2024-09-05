//
//  NewSongView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import SwiftUI

struct NewSongVariationView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @State var title = ""
    @State var lyrics = ""
    @State var errorMessage = ""
    
    @State var view2 = false
    @State var showError = false
    @State var showInfo = false
    @State var canDismissProgrammatically = false
    
    @Binding var isDisplayed: Bool
    @Binding var createdId: String
    
    @FocusState var isFocused: Bool
    
    let song: Song
    
    func createVariation() {
        songViewModel.createSongVariation(song: song, lyrics: lyrics, title: title) { error, createdId in
            if let error = error {
                print(error.localizedDescription)
                self.errorMessage = error.localizedDescription
                self.showError = true
            } else {
                self.createdId = createdId
                self.canDismissProgrammatically = true
                self.view2 = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Enter a name for your new variation.")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                SheetCloseButton {
                    isDisplayed = false
                }
            }
            .padding()
            Divider()
            Spacer()
            TextField(NSLocalizedString("title", comment: ""), text: $title)
                .padding(14)
                .background(Material.regular)
                .clipShape(Capsule())
                .focused($isFocused)
                .padding()
            Spacer()
            Divider()
            LiveLyricsButton("Continue", showProgressIndicator: false, action: { view2 = true })
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
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .padding()
        }
        .onAppear {
            isFocused = true
        }
    }
    
    var nextView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Enter the lyrics for the variation.")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                SheetCloseButton {
                    view2 = false
                }
            }
            .padding()
            Divider()
            TextEditor(text: $lyrics)
                .padding(.horizontal)
                .focused($isFocused)
            Divider()
            LiveLyricsButton("Continue", action: {
                if lyrics.isEmpty {
                    showInfo.toggle()
                } else {
                    createVariation()
                }
            })
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert(isPresented: $showInfo) {
            Alert(title: Text("You need to add lyrics to a variation to create it."), dismissButton: .cancel() )
        }
        .onAppear {
            isFocused = true
        }
    }
}
