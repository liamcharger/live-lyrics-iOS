//
//  BandMemberRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/24/24.
//

import SwiftUI

struct BandMemberRowView: View {
    let member: BandMember
    
    var body: some View {
        Group {
            VStack(spacing: 12) {
                let role = BandsViewModel.shared.memberRoles.first(where: { $0.id! == member.roleId ?? "" })
                
                BandMemberPopoverRowView(member: member, size: [21: 18])
                Text(member.fullname.replacingOccurrences(of: " ", with: "\n"))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .font(.title3.weight(.bold))
                if let role {
                    HStack {
                        FAText(iconName: role.icon ?? "", size: 16)
                        Text(role.name)
                    }
                    .padding(10)
                    .padding(.horizontal, 2)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
            .padding()
            .frame(minWidth: 140)
            .background(Material.thin)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .frame(maxWidth: 180)
    }
}

#Preview {
    BandMemberRowView(member: BandMember(uid: "uid", fullname: "John Doe", username: "johndoe", roleId: "keyboardist", fcmId: ""))
}
