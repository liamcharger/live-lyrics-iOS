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
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                HStack {
                    Text("Choose a Role")
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                    Spacer()
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
                    LazyVGrid(columns: columns) {
                        ForEach(bandsViewModel.memberRoles, id: \.name) { role in
                            Button {
                                selectedRole = (selectedRole == nil ? role : nil)
                                
                                if let member = member, let band = band {
                                    bandsViewModel.saveRole(to: member, for: band, role: selectedRole)
                                }
                                
                                if selectedRole != nil {
                                    dismiss()
                                }
                            } label: {
                                ContentRowView(role.name, icon: role.icon ?? "star", isSelected: (selectedRole?.name ?? "") == role.name, showChevron: false)
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
