//
//  ListRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI
import FASwiftUI

struct ListRowView: View {
    @EnvironmentObject var viewModel: AuthViewModel
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
                Text(title)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                if let song = subtitleForSong {
                    if viewModel.currentUser?.showDataUnderSong != "None" {
                        if viewModel.currentUser?.showDataUnderSong == "Show Lyrics" {
                            Text(subtitleForSong?.lyrics ?? "No lyrics")
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.gray)
                        } else if viewModel.currentUser?.showDataUnderSong == "Show Date" {
                            Text(song.timestamp.formatted())
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.gray)
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
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 30))
    }
}

struct ListViewModifier: ViewModifier {
    let capsule: Bool
    
    func body(content: Content) -> some View {
        if !capsule {
            content
                .cornerRadius(30)
        } else {
            content
                .clipShape(Capsule())
        }
    }
}

#Preview {
    ListRowView(isEditing: .constant(true), title: "Favorites", navArrow: nil, imageName: "pin.fill", icon: "folder", subtitleForSong: Song.song)
}
