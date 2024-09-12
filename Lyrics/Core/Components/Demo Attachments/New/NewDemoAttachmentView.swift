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
    var processedUrl: String {
        if url.lowercased().hasPrefix("http://") || url.lowercased().hasPrefix("https://") {
            return url
        } else {
            return "https://\(url)"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("New Demo")
                    .font(.title.weight(.bold))
                Spacer()
                SheetCloseButton {
                    presMode.wrappedValue.dismiss()
                }
            }
            .padding()
            Divider()
            VStack {
                Spacer()
                VStack(spacing: 4) {
                    CustomTextField(text: $url, placeholder: "URL")
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .focused($isFocused)
                }
                .padding()
                Spacer()
                Divider()
                LiveLyricsButton("Save") {
                    songViewModel.createDemoAttachment(for: song, from: url) {
                        presMode.wrappedValue.dismiss()
                    }
                }
                .padding()
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}
