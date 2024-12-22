//
//  NewFolderView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import SwiftUI

struct NewFolderView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @State var title = ""
    @State var lyrics = ""
    @State var errorMessage = ""
    
    @State var view2 = false
    @State var view3 = false
    @State var showError = false
    
    @Binding var isDisplayed: Bool
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Enter a name for your folder.")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                CloseButton {
                    isDisplayed = false
                }
            }
            .padding()
            Divider()
            Spacer()
            CustomTextField(text: $title, placeholder: "title", image: "character.cursor.ibeam")
                .padding()
                .focused($isFocused)
            Spacer()
            Divider()
            LiveLyricsButton("Continue", action: {
                songViewModel.createFolder(title: title) { error in
                    if let error = error {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
                    isDisplayed = false
                }
            })
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(title.isEmpty ? 0.5 : 1)
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .onAppear {
            isFocused = true
        }
    }
}
