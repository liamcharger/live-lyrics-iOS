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
    @ObservedObject var mainViewModel = MainViewModel.shared
    
    @Binding var band: Band?
    
    let pasteboard = UIPasteboard.general
    
    @State private var bandMembers = [BandMember]()
    @State private var selectedMember: BandMember?
    @State private var roles = [BandRole]()
    
    @State private var loadingMembers = true
    @State private var loadingRoles = true
    @State private var showCopiedAlert = false
    @State private var showDeleteConfirmation = false
    
    private var songs: [Song] {
        let songs = mainViewModel.songs + mainViewModel.sharedSongs
        
        return songs.filter { song in
            if let songBandId = song.bandId, let bandId = band?.id {
                return songBandId == bandId
            }
            return false
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CloseButton {
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
                                
                                let invite = HeaderActionButton(title: NSLocalizedString("Invite", comment: ""), icon: "user-plus", scheme: .primary, action: {
                                    self.pasteboard.string = band.joinId
                                    self.showCopiedAlert = true
                                })
                                let leave = HeaderActionButton(title: bandsViewModel.bandCreator(band) ? NSLocalizedString("Delete", comment: "") : NSLocalizedString("Leave", comment: ""), icon: bandsViewModel.bandCreator(band) ? "trash-can" : "sf-rectangle.portrait.and.arrow.right", scheme: .destructive, action: {
                                    self.showDeleteConfirmation = true
                                })
                                
                                Group {
                                    if bandsViewModel.bandAdmin(band) {
                                        HeaderActionsView([
                                            invite,
                                            leave
                                        ])
                                    } else {
                                        HeaderActionsView([
                                            leave
                                        ])
                                    }
                                }
                                .confirmationDialog(bandsViewModel.bandCreator(band) ? "Delete Band" : "Leave Band", isPresented: $showDeleteConfirmation) {
                                    Button(bandsViewModel.bandCreator(band) ? "Delete" : "Leave", role: .destructive) {
                                        if bandsViewModel.bandCreator(band) {
                                            self.bandsViewModel.deleteBand(band)
                                        } else {
                                            self.bandsViewModel.leaveBand(band)
                                        }
                                        self.band = nil
                                    }
                                    Button("Cancel", role: .cancel) {}
                                } message: {
                                    Text("Are you sure you want to \(bandsViewModel.bandCreator(band) ? "delete" : "leave") \"\(band.name)\"? This action cannot be undone.")
                                }
                            }
                            .padding(.top)
                            .padding(.bottom, 6)
                            if #available(iOS 17, *), band.createdBy == uid() {
                                TipView(JoinBandTip())
                                    .tipViewStyle(LiveLyricsTipStyle())
                            }
                            VStack(spacing: 2) {
                                ListHeaderView(title: NSLocalizedString("band_members", comment: ""))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(bandMembers) { member in
                                            Button {
                                                selectedMember = member
                                            } label: {
                                                BandMemberRowView(member: member)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.horizontal, -16)
                            }
                            if !songs.isEmpty { // TODO: verify this section works properly
                                VStack(spacing: 2) {
                                    ListHeaderView(title: NSLocalizedString("shared_songs", comment: ""))
                                    VStack {
                                        ForEach(songs) { song in
                                            NavigationLink {
                                                SongDetailView(song: song, songs: songs)
                                                    .padding(.top, 10) // Add spacing to top of view since there are no status bar insets in the sheet
                                            } label: {
                                                ListRowView(title: song.title, navArrow: "chevron.right", sharedBadge: true, song: song)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    ProgressView("Loading")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
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
}
