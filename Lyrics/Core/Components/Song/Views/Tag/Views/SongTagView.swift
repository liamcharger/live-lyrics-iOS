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
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    func rowView(_ tag: TagSelectionEnum) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(songViewModel.getColorForTag(tag.rawValue))
                Spacer()
                if tags.contains(tag) {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.medium))
                        .foregroundColor(.gray)
                }
            }
            Text(NSLocalizedString("tag_\(tag.rawValue)", comment: ""))
                .font(.system(size: 18).weight(.semibold))
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Material.thin)
        .foregroundColor(.primary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tags")
                    .font(.system(size: 26, weight: .bold))
                Spacer()
                CloseButton {
                    isPresented = false
                }
            }
            .padding()
            Divider()
            ScrollView {
                LazyVGrid(columns: columns) {
                    Button(action: {
                        tags.removeAll()
                        tagsToUpdate.removeAll()
                        songViewModel.updateTagsForSong(song, tags: tags)
                        
                        for tag in tags {
                            self.tagsToUpdate.append(tag.rawValue)
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                                Spacer()
                                if !tags.contains(.blue) && !tags.contains(.green) && !tags.contains(.orange) && !tags.contains(.red) && !tags.contains(.yellow) {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.gray)
                                }
                            }
                            Text("None")
                                .font(.system(size: 18).weight(.semibold))
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Material.thin)
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                            rowView(fullTag)
                        }
                    }
                }
                .padding()
            }
        }
    }
}
