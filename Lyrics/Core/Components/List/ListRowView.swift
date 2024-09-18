//
//  ListRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

struct ListRowView: View {
    @ObservedObject var viewModel = AuthViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    
    let title: String
    let navArrow: String?
    let imageName: String?
    let icon: String?
    let badge: String?
    let sharedBadge: Bool?
    let song: Song?
    
    init(title: String, navArrow: String? = nil, imageName: String? = nil, icon: String? = nil, badge: String? = nil, sharedBadge: Bool? = nil, song: Song? = nil) {
        self.title = title
        self.navArrow = navArrow
        self.imageName = imageName
        self.icon = icon
        self.badge = badge
        self.sharedBadge = sharedBadge
        self.song = song
    }
    
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
                    if sharedBadge ?? true {
                        if let song = song, let userId = viewModel.currentUser?.id, song.uid != userId {
                            Image(systemName: "person.2")
                                .font(.system(size: 16).weight(.medium))
                        }
                    }
                    if let badge = badge {
                        Text(badge)
                            .padding(6)
                            .padding(.horizontal, 1.5)
                            .font(.system(size: 13).weight(.medium))
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    if let tags = song?.tags {
                        HStack(spacing: 5) {
                            ForEach(tags, id: \.self) { tag in
                                Circle()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(songViewModel.getColorForTag(tag))
                            }
                        }
                    }
                }
                if let song = song, let user = viewModel.currentUser {
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
        .modifier(ListViewModifier(capsule: {
            if song != nil {
                if let user = viewModel.currentUser {
                    if let showDataUnderSong = user.showDataUnderSong {
                        if showDataUnderSong == "None" {
                            return true
                        } else {
                            return false
                        }
                    } else {
                        return true
                    }
                } else {
                    return true
                }
            } else {
                return true
            }
        }()))
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
                .clipShape(RoundedRectangle(cornerRadius: 22))
        } else {
            content
                .clipShape(Capsule())
        }
    }
}

#Preview {
    ListRowView(title: "Favorites", navArrow: nil, imageName: "pin.fill", icon: "folder", song: Song.song)
}
