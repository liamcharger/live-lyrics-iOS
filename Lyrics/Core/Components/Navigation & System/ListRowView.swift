//
//  ListRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

struct ListRowView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @Binding var isEditing: Bool
    
    let title: String
    let navArrow: String?
    let imageName: String?
    let icon: String?
    let subtitleForSong: Song?
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(title)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    if let tags = subtitleForSong?.tags {
                        HStack(spacing: 5) {
                            ForEach(tags, id: \.self) { tag in
                                Circle()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(songViewModel.getColorForTag(tag))
                            }
                        }
                    }
                }
                if let song = subtitleForSong, let user = viewModel.currentUser {
                    if user.showDataUnderSong != "None" {
                        switch user.showDataUnderSong {
                        case "Show Lyrics":
                            Text(!song.lyrics.isEmpty ? song.lyrics : "No lyrics")
                                .modifier(SubtitleViewModifier())
                        case "Show Date":
                            Text(song.timestamp.formatted())
                                .modifier(SubtitleViewModifier())
                        case "Show Artist":
                            if let artist = song.artist {
                                Text(!artist.isEmpty ? artist : "No artist")
                                    .modifier(SubtitleViewModifier())
                            } else {
                                Text("No artist")
                                    .modifier(SubtitleViewModifier())
                            }
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            Spacer()
            if let imageName = imageName {
                if imageName != "" {
                    FAText(iconName: imageName, size: 18)
                        .foregroundColor(.yellow)
                }
            }
            if let navArrow = navArrow {
                Image(systemName: navArrow)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Material.regular)
        .foregroundColor(.primary)
        .modifier(ListViewModifier(capsule: subtitleForSong == nil))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 22))
    }
}

struct SubtitleViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .foregroundColor(.gray)
    }
}
struct ListViewModifier: ViewModifier {
    let capsule: Bool
    
    func body(content: Content) -> some View {
        if !capsule {
            content
                .cornerRadius(22)
        } else {
            content
                .clipShape(Capsule())
        }
    }
}

#Preview {
    ListRowView(isEditing: .constant(true), title: "Favorites", navArrow: nil, imageName: "pin.fill", icon: "folder", subtitleForSong: Song.song)
}
