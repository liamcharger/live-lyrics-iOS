//
//  BandMemberPopoverRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/2/24.
//

import SwiftUI

struct BandMemberPopoverRowView: View {
    let member: BandMember
    let showBadge: Bool
    let size: [CGFloat: CGFloat]
    
    var small: Bool {
        return size == [16: 12]
    }
    var badgeDimensions: CGFloat {
        return small ? 22 : 33
    }
    
    init(member: BandMember, size: [CGFloat: CGFloat]? = nil, showBadge: Bool? = nil) {
        self.member = member
        self.showBadge = showBadge ?? true
        self.size = size ?? [16: 12]
    }
    
    var body: some View {
        Text(member.fullname.components(separatedBy: " ").filter { !$0.isEmpty }.reduce("") { ($0 == "" ? "" : "\($0.first!)") + "\($1.first!)" })
            .padding(size.values.first!)
            .font(.system(size: size.keys.first!).weight(.medium))
            .background(Material.regular)
            .clipShape(Circle())
            .overlay {
                if let roleIcon = member.roleIcon, showBadge {
                    FAText(iconName: roleIcon, size: small ? 11 : 17)
                        .foregroundColor(.white)
                        .background {
                            Circle()
                                .foregroundColor(Color.accentColor)
                                .frame(width: badgeDimensions, height: badgeDimensions)
                        }
                        .offset(x: small ? 15 : 35, y: small ? -13 : -25)
                        .shadow(radius: 3)
                }
            }
    }
}
