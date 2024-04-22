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
    @State var lyrics = ""
    @State var errorMessage = ""
    
    @State var view2 = false
    @State var showError = false
    @State var showInfo = false
    @State var canDismissProgrammatically = false
    
    @Binding var isDisplayed: Bool
    
    @FocusState var isTitleFocused: Bool
    @FocusState var isLyricsFocused: Bool
    
    let folder: Folder?
    
    func createSong() {
        songViewModel.createSong(lyrics: lyrics, title: title) { success, errorMessage in
            if success {
                canDismissProgrammatically = true
                view2 = false
            } else {
                self.errorMessage = errorMessage
                showError = true
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Enter a name for your song.")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                SheetCloseButton(isPresented: $isDisplayed)
            }
            .padding()
            Divider()
            Spacer()
            CustomTextField(text: $title, placeholder: "Title")
                .focused($isTitleFocused)
                .padding()
            Spacer()
            Divider()
            Button(action: {
                view2.toggle()
            }, label: {
                HStack {
                    Spacer()
                    Text(NSLocalizedString("continue", comment: "Continue"))
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
            })
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
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
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
                SheetCloseButton(isPresented: $view2)
            }
            .padding()
            Divider()
            TextEditor(text: $lyrics)
                .padding(.horizontal)
                .focused($isLyricsFocused)
            Divider()
            Button {
                if lyrics.isEmpty {
                    showInfo.toggle()
                } else {
                    createSong()
                }
            } label: {
                Text(NSLocalizedString("continue", comment: "Continue"))
                    .modifier(NavButtonViewModifier())
            }
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert("Your song doesn't have any lyrics. Continue anyway?", isPresented: $showInfo, actions: {
            Button(action: createSong, label: {Text(NSLocalizedString("continue", comment: "Continue"))})
            Button(role: .cancel, action: {}, label: {Text("Cancel")})
        })
        .onAppear {
            isLyricsFocused = true
        }
    }
}
