//
//  BandMemberAddRoleView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/3/24.
//

import SwiftUI
import BottomSheet

struct BandMemberAddRoleView: View {
    @Environment(\.dismiss) var dismiss
    
    let member: BandMember?
    let band: Band?
    
    @Binding var selectedRole: BandRole?
    
    @State var showCustomRoleSheet = false
    
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                HStack {
                    Text("Choose a Role")
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                    Spacer()
                    if selectedRole != nil {
                        Button(action: {
                            selectedRole = nil
                            if let member = member, let band = band {
                                bandsViewModel.saveRole(to: member, for: band, role: nil)
                            }
                            dismiss()
                        }) {
                            FAText(iconName: "trash-can", size: 19)
                                .padding(12)
                                .foregroundColor(.primary)
                                .background(Material.regular)
                                .clipShape(Circle())
                        }
                    }
                    Button(action: {dismiss()}) {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .padding(12)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                }
                .padding()
                Divider()
                    .padding(.horizontal, -12)
                ScrollView {
                    VStack {
                        ForEach(bandsViewModel.memberRoles, id: \.name) { role in
                            Button {
                                selectedRole = role
                                if let member = member, let band = band {
                                    bandsViewModel.saveRole(to: member, for: band, role: role)
                                }
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Group {
                                        FAText(iconName: role.icon ?? "star", size: 20)
                                        Text(role.name)
                                    }
                                    .foregroundColor(.primary)
                                    Spacer()
                                    if let selectedRole = selectedRole, selectedRole.name == role.name {
                                        Image(systemName: "checkmark")
                                            .font(.body.weight(.medium))
                                    }
                                }
                                .padding()
                                .background(Material.regular)
                                .clipShape(Capsule())
                            }
                        }
                        /*
                         Button {
                         showCustomRoleSheet = true
                         } label: {
                         HStack(spacing: 8) {
                         Group {
                         FAText(iconName: "plus", size: 20)
                         Text("Custom")
                         }
                         .foregroundColor(.primary)
                         Spacer()
                         if let selectedRole = selectedRole, selectedRole.name == "Custom" {
                         Image(systemName: "checkmark")
                         .font(.body.weight(.medium))
                         }
                         }
                         .padding()
                         .background(Material.regular)
                         .clipShape(Capsule())
                         }
                         */
                    }
                    .padding()
                }
            }
            .bottomSheet(isPresented: $showCustomRoleSheet, detents: [.medium()]) {
                if let member = member, let band = band {
                    BandChooseRoleView(member: member, band: band, selectedRole: $selectedRole)
                }
            }
        }
    }
}
