//
//  SongTagView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/2/24.
//

import SwiftUI

struct SongTagView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @Binding var isPresented: Bool
    @Binding var tagsToUpdate: [String]
    
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
                    Button(action: {
                        tags.removeAll()
                        tagsToUpdate.removeAll()
                        songViewModel.updateTagsForSong(song, tags: tags)
                        
                        for tag in tags {
                            self.tagsToUpdate.append(tag.rawValue)
                        }
                    }) {
                        HStack {
                            Text("None")
                            Spacer()
                            if !tags.contains(.blue) && !tags.contains(.green) && !tags.contains(.orange) && !tags.contains(.red) && !tags.contains(.yellow) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding()
                        .font(.body.weight(.semibold))
                        .background(Material.regular)
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                    }
                    ForEach(TagSelectionEnum.allTags, id: \.self) { fullTag in
                        Button(action: {
                            tags.removeAll()
                            tagsToUpdate.removeAll()
                            tags.append(fullTag)
                            
                            songViewModel.updateTagsForSong(song, tags: tags)
                            
                            for tag in tags {
                                self.tagsToUpdate.append(tag.rawValue)
                            }
                        }) {
                            HStack {
                                Text(NSLocalizedString("tag_\(fullTag.rawValue)", comment: ""))
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
