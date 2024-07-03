//
//  BandMemberPopover.swift
//  Lyrics
//
//  Created by Liam Willey on 7/2/24.
//

import SwiftUI

struct BandMemberPopover: View {
    @Environment(\.dismiss) var dismiss
    
    let member: BandMember
    
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    @State var showRemoveSheet = false
    @State var readOnly = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {dismiss()}) {
                Image(systemName: "xmark")
                    .imageScale(.medium)
                    .padding(12)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                    .background(Material.regular)
                    .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            VStack(spacing: 10) {
                Spacer()
                BandMemberPopoverRowView(member: member, size: [35: 24], showBadge: false)
                VStack(spacing: 6) {
                    Text(member.fullname)
                        .multilineTextAlignment(.center)
                        .font(.largeTitle.weight(.bold))
                    HStack(spacing: 4) {
                        Text(member.username)
                            .font(.system(size: 20).weight(.semibold))
                        Text("#" + member.uid.prefix(4).uppercased())
                    }
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                }
                if let role = member.role {
                    HStack(spacing: 8) {
                        // Better icon than "star"?
                        FAText(iconName: member.roleIcon ?? "star", size: 23)
                            .background(Color.blue)
                            .foregroundColor(.white)
                        Text(role.capitalized)
                            .font(.body.weight(.semibold))
                    }
                    .padding()
                    .background {
                        if let color = member.roleColor {
                            if !color.isEmpty {
                                return bandsViewModel.getRoleColor(color)
                            }
                        }
                        return Color.blue
                    }
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(14)
                }
                Spacer()
            }
        }
        .padding(12)
        .confirmationDialog("Remove Band Member?", isPresented: $showRemoveSheet) {
            Button("Remove", role: .destructive) {
                
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \"\(member.username)\" as a member of this band? They will immediately lose access.")
        }
    }
}
