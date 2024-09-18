//
//  BandDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/16/24.
//

import SwiftUI
import TipKit

struct BandDetailView: View {
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    @Binding var band: Band?
    
    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]
    let pasteboard = UIPasteboard.general
    
    @State var bandMembers = [BandMember]()
    @State var selectedMember: BandMember?
    @State var roles = [BandRole]()
    
    @State var loadingMembers = true
    @State var loadingRoles = true
    @State var showCopiedAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            SheetCloseButton {
                band = nil
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding()
            Divider()
            if let band = band, !loadingMembers || !loadingRoles {
                ScrollView {
                    VStack(spacing: 22) {
                        VStack(spacing: 14) {
                            VStack {
                                FAText(iconName: "guitar", size: 35)
                                    .padding(24)
                                    .background(Material.regular)
                                    .clipShape(Circle())
                                VStack(spacing: 4) {
                                    Text(band.name)
                                        .multilineTextAlignment(.center)
                                        .font(.largeTitle.weight(.bold))
                                    Text("\(band.members.count) member\(band.members.count == 1 ? "" : "s")")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            let bandCreator = band.createdBy == SongDetailViewModel.shared.uid()
                            
                            HeaderActionsView([
                                .init(title: NSLocalizedString("Get Join Code", comment: ""), icon: "link", scheme: .primaryAlt, action: {
                                    self.pasteboard.string = band.joinId
                                    self.showCopiedAlert = true
                                }),
                                .init(title: bandCreator ? NSLocalizedString("Delete", comment: "") : NSLocalizedString("Leave", comment: ""), icon: bandCreator ? "fa-trash-can" : "rectangle.portrait.and.arrow.right", scheme: .destructive, action: {
                                    if bandCreator {
                                        self.bandsViewModel.deleteBand(band)
                                    } else {
                                        self.bandsViewModel.leaveBand(band)
                                    }
                                    self.band = nil
                                })
                            ])
                        }
                        .padding(.top)
                        .padding(.bottom, 6)
                        if #available(iOS 17, *) {
                            TipView(JoinBandTip())
                                .tipViewStyle(LiveLyricsTipStyle())
                        }
                        VStack(spacing: 2) {
                            ListHeaderView(title: NSLocalizedString("band_members", comment: ""))
                            LazyVGrid(columns: columns) {
                                ForEach(bandMembers) { member in
                                    let role = roles.first(where: { $0.id! == member.roleId ?? "" })
                                      
                                    Button {
                                        selectedMember = member
                                    } label: {
                                        BandMemberPopoverRowView(member: member, size: [18: 14], showBadge: true, role: role)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        VStack {
                            ListHeaderView(title: NSLocalizedString("shared_songs", comment: ""))
                        }
                    }
                    .padding()
                }
            } else {
                ProgressView("loading")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .bottomSheet(item: $selectedMember, detents: [.medium()]) {
            if let band = band, let member = selectedMember {
                BandMemberPopover(member: member, band: band)
            }
        }
        .alert(isPresented: $showCopiedAlert) {
            Alert(title: Text("Success!"), message: Text("band_join_code_copied"), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            if let band = band {
                bandsViewModel.fetchBandMembers(band) { members in
                    self.bandMembers = members
                    self.loadingMembers = false
                }
                bandsViewModel.fetchMemberRoles(band) { roles in
                    self.loadingRoles = false
                    self.roles = roles
                }
            }
        }
    }
}
