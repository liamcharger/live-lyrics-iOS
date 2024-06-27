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
    var small: Bool {
        return size == [16: 12]
    }
    var ownerBadgeDimensions: CGFloat {
        return small ? 22 : 33
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
                    FAText(iconName: "crown", size: small ? 11 : 17)
                        .foregroundColor(.white)
                        .background {
                            Circle()
                                .foregroundColor(Color.accentColor)
                                .frame(width: ownerBadgeDimensions, height: ownerBadgeDimensions)
                        }
                        .offset(x: small ? 15 : 35, y: small ? -13 : -25)
                        .shadow(radius: 3)
                }
            }
    }
}
