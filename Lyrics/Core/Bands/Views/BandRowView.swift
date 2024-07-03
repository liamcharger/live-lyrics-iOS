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
    @Binding var selectedMember: BandMember?
    
    @State var loadingMembers = true
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
                        Label("Get Code", systemImage: "lock.open")
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
            if loadingMembers {
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
                            Button {
                                selectedMember = member
                                showUserPopover = true
                            } label: {
                                BandMemberPopoverRowView(member: member)
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
//                self.members.append(BandMember(id: UUID().uuidString, uid: AuthViewModel.shared.currentUser?.id ?? "", fullname: "Liam Willey", username: "liamcharger", admin: true, role: "vocalist", roleColor: nil, roleIcon: "microphone-stand"))
            }
        }
    }
}
