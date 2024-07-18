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
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    @State var members = [BandMember]()
    @State var roles = [BandRole]()
    @Binding var selectedMember: BandMember?
    @Binding var selectedBand: Band?
    @Binding var showToast: Bool
    
    @State var loadingMembers = true
    @State var loadingRoles = true
    @Binding var showUserPopover: Bool
    @Binding var isSheetPresented: Bool
    
    var uid: String {
        return authViewModel.currentUser?.id ?? ""
    }
    
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
                        
                        showToast = true
                    } label: {
                        Label("Get Join Code", systemImage: "lock.open")
                    }
                    if members.contains(where: { $0.uid == uid }) {
                        Button(role: .destructive) {
                            // TODO: add confirmation
                            bandsViewModel.deleteBand(band)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } else {
                        Button(role: .destructive) {
                            bandsViewModel.leaveBand(band)
                        } label: {
                            // TODO: add confirmation
                            Label("Leave", systemImage: "trash")
                        }
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
                                // Use guard variable to check if sheet is already up, otherwise multiple sheets will present if the user is in more than one joined band
                                guard !isSheetPresented else { return }
                                selectedMember = member
                                selectedBand = band
                                showUserPopover = true
                                isSheetPresented = true
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
        .onDisappear {
            isSheetPresented = false
        }
    }
}
