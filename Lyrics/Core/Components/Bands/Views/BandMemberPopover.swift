//
//  BandMemberPopover.swift
//  Lyrics
//
//  Created by Liam Willey on 7/2/24.
//

import SwiftUI
import BottomSheet

struct BandMemberPopover: View {
    @Environment(\.dismiss) var dismiss
    
    let member: BandMember
    let band: Band
    
    @State var role: BandRole?
    
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    @State var showRemoveSheet = false
    @State var showAddRoleView = false
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
                HStack(spacing: 7) {
                    Spacer()
                    Button {
                        showAddRoleView = true
                    } label: {
                        if let role = role {
                            HStack(spacing: 7) {
                                // Better icon than "star"?
                                FAText(iconName: role.icon ?? "star", size: 18)
                                Text(role.name.capitalized)
                                    .font(.body.weight(.semibold))
                            }
                            .padding(10)
                            .padding(.horizontal, 8)
                            .background {
                                if let color = role.color, !color.isEmpty {
                                    return bandsViewModel.getRoleColor(color)
                                }
                                return Color.blue
                            }
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        } else if bandsViewModel.bandAdmin(band) {
                            HStack(spacing: 7) {
                                FAText(iconName: "plus", size: 18)
                                Text("Add Role")
                                    .font(.body.weight(.semibold))
                            }
                            .padding(10)
                            .padding(.horizontal, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                    }
                    .disabled(!bandsViewModel.bandAdmin(band))
                    if bandsViewModel.bandAdmin(band) && member.uid != uid() {
                        Button {
                            showRemoveSheet = true
                        } label: {
                            HStack(spacing: 7) {
                                Text("Remove")
                                FAText(iconName: "square-arrow-right", size: 18)
                            }
                            .foregroundColor(.red)
                            .padding(10)
                            .padding(.horizontal, 8)
                            .background(Material.regular)
                            .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                .padding(12)
                Spacer()
            }
        }
        .padding(12)
        .bottomSheet(isPresented: $showAddRoleView, detents: [.medium()], onDismiss: {}) {
            BandMemberAddRoleView(member: member, band: band, selectedRole: $role)
        }
        .confirmationDialog("Remove Band Member?", isPresented: $showRemoveSheet) {
            Button("Remove", role: .destructive) {
                bandsViewModel.leaveBand(band, uid: member.uid)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \"\(member.username)\" as a member of this band? They will immediately lose access.")
        }
        .onAppear {
            bandsViewModel.fetchMemberRoles(band) { roles in
                self.role = roles.first(where: { $0.id! == member.roleId ?? "" })
            }
        }
    }
}
