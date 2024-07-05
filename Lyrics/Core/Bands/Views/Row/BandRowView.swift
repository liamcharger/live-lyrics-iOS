//
//  BandRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import SwiftUI

struct BandRowView: View {
    let band: Band
    
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    @State var members = [BandMember]()
    @State var roles = [BandRole]()
    @Binding var selectedMember: BandMember?
    
    @State var loadingMembers = true
    @State var loadingRoles = true
    @Binding var showUserPopover: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(band.name)
                        .font(.title2.weight(.bold))
                    Text("\(band.members.count) member\(band.members.count == 1 ? "" : "s")")
                        .foregroundColor(.gray)
                }
                Spacer()
                // Notes button for band-public notes?
                Menu {
                    Button {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = band.joinId
                        // TODO: create user visible confirmation
                    } label: {
                        Label("Get Join Code", systemImage: "lock.open")
                    }
                    // TODO: update button display logic
                    Button(role: .destructive) {
                        bandsViewModel.leaveBand(band)
                    } label: {
                        Label("Leave", systemImage: "trash")
                    }
                    Button(role: .destructive) {
                        bandsViewModel.deleteBand(band)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(14)
                        .background(Material.regular)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                }
            }
            .padding()
            Divider()
            if loadingMembers || loadingRoles {
                HStack(spacing: 5) {
                    Spacer()
                    ProgressView()
                    Text("Loading")
                    Spacer()
                }
                .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(members) { member in
                            let role = roles.first(where: { $0.id! == member.roleId ?? "" })
                            
                            Button {
                                selectedMember = member
                                showUserPopover = true
                            } label: {
                                BandMemberPopoverRowView(member: member, role: role)
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            bandsViewModel.fetchBandMembers(band) { members in
                self.loadingMembers = false
                self.members = members
            }
            bandsViewModel.fetchMemberRoles(band) { roles in
                self.loadingRoles = false
                self.roles = roles
            }
        }
    }
}
