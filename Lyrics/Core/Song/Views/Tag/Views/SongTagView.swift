//
//  SongTagView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/2/24.
//

import SwiftUI
import FASwiftUI

struct SongTagView: View {
    @ObservedObject var songViewModel = SongViewModel()
    
    @Binding var isPresented: Bool
    
    @State var tags: [TagSelectionEnum]
    
    let song: Song
    private let tagOptions: [TagSelectionEnum] = [.blue, .green, .yellow, .red, .orange]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tags")
                    .font(.system(size: 26, weight: .bold))
                Spacer()
                SheetCloseButton(isPresented: $isPresented)
            }
            .padding()
            Divider()
            ScrollView {
                VStack {
                    ForEach(tagOptions, id: \.self) { fullTag in
                        Button(action: {
                            tags.removeAll()
                            tags.append(fullTag)
                            songViewModel.updateTagsForSong(song, tags: tags)
                        }) {
                            TagRowView(tag: fullTag, isSelected: tags.contains(fullTag))
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct TagRowView: View {
    @ObservedObject var songViewModel = SongViewModel()
    let tag: TagSelectionEnum
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(tag.rawValue.capitalized)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .padding()
        .font(.body.weight(.semibold))
        .background {
            Capsule()
                .stroke(songViewModel.getColorForTag(tag.rawValue), lineWidth: 5)
        }
        .foregroundColor(songViewModel.getColorForTag(tag.rawValue))
        .clipShape(Capsule())
    }
}
