//
//  BandMemberPopoverRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/2/24.
//

import SwiftUI

struct BandMemberPopoverRowView: View {
    let member: BandMember
    let role: BandRole?
    let showBadge: Bool
    let size: [CGFloat: CGFloat]
    
    var badgeDimensions: CGFloat {
        switch size {
        case [16: 12]:
            return 22
        case [35: 24]:
            return 33
        default:
            return 28
        }
    }
    var iconSize: CGFloat {
        switch size {
        case [16: 12]:
            return 11
        case [35: 24]:
            return 17
        default:
            return 12
        }
    }
    var offset: CGSize {
        switch size {
        case [16: 12]:
            return CGSizeMake(15, -13)
        case [35: 24]:
            return CGSizeMake(35, -25)
        default:
            return CGSizeMake(20, -18)
        }
    }
    
    init(member: BandMember, size: [CGFloat: CGFloat]? = nil, showBadge: Bool? = nil, role: BandRole? = nil) {
        self.member = member
        self.role = role
        self.showBadge = showBadge ?? true
        self.size = size ?? [16: 12]
    }
    
    var body: some View {
        Text(member.fullname.components(separatedBy: " ").filter { !$0.isEmpty }.reduce("") { ($0 == "" ? "" : "\($0.first!)") + "\($1.first!)" })
            .padding(size.values.first!)
            .font(.system(size: size.keys.first!).weight(.medium))
            .background(Color(.darkGray).opacity(0.35))
            .clipShape(Circle())
            .overlay {
                if let role = role, showBadge {
                    FAText(iconName: role.icon ?? "star", size: iconSize)
                        .foregroundColor(.white)
                        .background {
                            Circle()
                                .foregroundColor(Color.accentColor)
                                .frame(width: badgeDimensions, height: badgeDimensions)
                        }
                        .offset(offset)
                        .shadow(radius: 3)
                }
            }
    }
}
