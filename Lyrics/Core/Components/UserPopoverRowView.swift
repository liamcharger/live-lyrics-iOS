//
//  UserPopoverRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/15/24.
//

import SwiftUI

struct UserPopoverRowView: View {
    let user: User
    let song: Song?
    let folder: Folder?
    let size: [CGFloat: CGFloat]
    
    var uid: String {
        if let song = song {
            return song.uid
        } else if let folder = folder {
            return folder.uid ?? ""
        }
        return ""
    }
    
    init(user: User, song: Song? = nil, folder: Folder? = nil, size: [CGFloat: CGFloat]? = nil) {
        self.user = user
        self.song = song
        self.folder = folder
        self.size = size ?? [16: 12]
    }
    
    var body: some View {
        Text(user.fullname.components(separatedBy: " ").filter { !$0.isEmpty }.reduce("") { ($0 == "" ? "" : "\($0.first!)") + "\($1.first!)" })
            .padding(size.values.first!)
            .font(.system(size: size.keys.first!).weight(.medium))
            .background(Material.regular)
            .clipShape(Circle())
            .overlay {
                if uid == user.id! {
                    FAText(iconName: "crown", size: 11)
                        .foregroundColor(.white)
                        .background {
                            Circle()
                                .foregroundColor(Color.accentColor)
                                .frame(width: 22, height: 22)
                        }
                        .offset(x: 15, y: -13)
                        .shadow(radius: 3)
                }
            }
    }
}
