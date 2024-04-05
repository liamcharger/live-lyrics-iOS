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
                    ForEach(TagSelectionEnum.allTags, id: \.self) { fullTag in
                        Button(action: {
                            tags.removeAll()
                            tags.append(fullTag)
                            songViewModel.updateTagsForSong(song, tags: tags)
                        }) {
                            HStack {
                                Text(fullTag.rawValue.capitalized)
                                Spacer()
                                if tags.contains(fullTag) {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .padding()
                            .font(.body.weight(.semibold))
                            .background(Material.regular)
                            .foregroundColor(songViewModel.getColorForTag(fullTag.rawValue))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding()
            }
        }
    }
}
