//
//  NewDemoAttachmentView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/5/24.
//

import SwiftUI

struct NewDemoAttachmentView: View {
    @Environment(\.presentationMode) var presMode
    
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @State var url = ""
    
    @FocusState var isFocused: Bool
    
    let song: Song
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("New Demo")
                    .font(.title.weight(.bold))
                Spacer()
                CloseButton {
                    presMode.wrappedValue.dismiss()
                }
            }
            .padding()
            Divider()
            VStack {
                Spacer()
                VStack(spacing: 4) {
                    CustomTextField(text: $url, placeholder: "URL", image: "link")
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .focused($isFocused)
                }
                .padding()
                Spacer()
                Divider()
                LiveLyricsButton("Save") {
                    songViewModel.createDemoAttachment(for: song, from: songViewModel.appendPrefix(url)) {
                        presMode.wrappedValue.dismiss()
                    }
                }
                .disabled(url.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(url.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .padding()
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}
