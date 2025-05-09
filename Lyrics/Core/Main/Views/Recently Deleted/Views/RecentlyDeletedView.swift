//
//  RecentlyDeletedView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/26/23.
//

import SwiftUI

struct RecentlyDeletedView: View {
    @ObservedObject var recentlyDeletedViewModel = RecentlyDeletedViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    @State var searchText = "" // FIXME: implement search, or remove references
    
    @State var showMenu = false
    @State var showNewSong = false
    @State var isEditing = false
    @State var collapsedTitle = false
    @State var showDeleteAllConfirmation = false
    
    @State private var selectedSong: RecentlyDeletedSong?
    @State private var showDeleteSheet = false
    
    var searchableSongs: [RecentlyDeletedSong] {
        if searchText.isEmpty {
            return recentlyDeletedViewModel.songs
        } else {
            let lowercasedQuery = searchText.lowercased()
            return recentlyDeletedViewModel.songs.filter ({
                $0.title.lowercased().contains(lowercasedQuery)
            })
        }
    }
    
    func performAction(for song: RecentlyDeletedSong) {
        selectedSong = song
        showDeleteSheet.toggle()
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                CustomNavBar(NSLocalizedString("recently_deleted", comment: ""), showBackButton: true, collapsed: .constant(false), collapsedTitle: $collapsedTitle)
                Divider()
                ScrollView {
                    VStack(alignment: .leading) {
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollViewOffsetPreferenceKey.self, value: [geo.frame(in: .global).minY])
                        }
                        .frame(height: 0)
                        HeaderView("Recently \nDeleted", icon: "trash-can", color: .red, geo: geo, counter: "\(recentlyDeletedViewModel.songs.count) song\(recentlyDeletedViewModel.songs.count == 1 ? "" : "s")".uppercased())
                        AdBannerView(unitId: "ca-app-pub-5671219068273297/5562143788", height: 80, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0)
                        if recentlyDeletedViewModel.isLoadingSongs || searchableSongs.isEmpty {
                            FullscreenMessage(imageName: "circle.slash", title: "You don't have any recently deleted songs\(searchText.isEmpty ? "" : " that matched your search").", isLoading: recentlyDeletedViewModel.isLoadingSongs)
                                .frame(maxWidth: .infinity)
                                .frame(height: geo.size.height / 2.2, alignment: .bottom)
                        } else {
                            Text("Deleted songs are stored for thirty days before being permanently removed.")
                                .foregroundColor(Color.gray)
                                .deleteDisabled(true)
                                .padding(.horizontal, 10)
                            Divider()
                                .padding(.horizontal, -16)
                            ForEach(searchableSongs, id: \.id) { recentlyDeletedSong in
                                let song = Song(
                                    id: recentlyDeletedSong.id!,
                                    uid: recentlyDeletedSong.uid,
                                    timestamp: recentlyDeletedSong.timestamp,
                                    lastSynced: nil,
                                    lastEdited: nil,
                                    lastLyricsEdited: nil,
                                    title: recentlyDeletedSong.title,
                                    lyrics: recentlyDeletedSong.lyrics,
                                    order: recentlyDeletedSong.order,
                                    key: recentlyDeletedSong.key,
                                    notes: recentlyDeletedSong.notes,
                                    size: recentlyDeletedSong.size,
                                    weight: recentlyDeletedSong.weight,
                                    alignment: recentlyDeletedSong.alignment,
                                    lineSpacing: recentlyDeletedSong.lineSpacing,
                                    artist: recentlyDeletedSong.artist,
                                    bpm: recentlyDeletedSong.bpm,
                                    bpb: recentlyDeletedSong.bpb,
                                    pinned: recentlyDeletedSong.pinned,
                                    performanceMode: recentlyDeletedSong.performanceMode,
                                    tags: recentlyDeletedSong.tags,
                                    demoAttachments: nil,
                                    bandId: nil,
                                    autoscrollTimestamps: nil,
                                    joinedUsers: nil,
                                    variations: nil,
                                    readOnly: nil
                                )
                                
                                NavigationLink(destination: SongDetailView(song: song, restoreSong: recentlyDeletedSong)) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(recentlyDeletedSong.title)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        let daysLeft = 30 - Calendar.current.dateComponents([.day], from: recentlyDeletedSong.deletedTimestamp, to: Date()).day!
                                        if daysLeft <= 7 {
                                            Text("\(daysLeft) day\(daysLeft == 1 ? "" : "s")")
                                                .font(.body.weight(.semibold))
                                                .foregroundColor(.red)
                                        }
                                        Text("\(recentlyDeletedSong.deletedTimestamp.formatted())").foregroundColor(Color.gray)
                                    }
                                    .padding()
                                    .background(Material.regular)
                                    .foregroundColor(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 20))
                                    .contextMenu {
                                        Button {
                                            recentlyDeletedViewModel.restoreSong(song: recentlyDeletedSong)
                                        } label: {
                                            Label("Restore", systemImage: "clock.arrow.circlepath")
                                        }
                                        Button(role: .destructive) {
                                            performAction(for: recentlyDeletedSong)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                        let animation = Animation.easeInOut(duration: 0.22)
                        
                        if value.first ?? 0 >= -40 {
                            DispatchQueue.main.async {
                                withAnimation(animation) {
                                    collapsedTitle = false
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                withAnimation(animation) {
                                    collapsedTitle = true
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, !searchableSongs.contains(where: { $0.title == "noSongs" }) ? 75 : 0)
                    .confirmationDialog("Delete Song", isPresented: $showDeleteSheet) {
                        if let selectedSong = selectedSong {
                            Button("Delete", role: .destructive) {
                                print("Deleting song: \(selectedSong.title)")
                                recentlyDeletedViewModel.deleteSong(song: selectedSong)
                                recentlyDeletedViewModel.fetchRecentlyDeletedSongs()
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                    } message: {
                        if let selectedSong = selectedSong {
                            Text("Are you sure you want to permanently delete \"\(selectedSong.title)\"?")
                        }
                    }
                }
            }
            .overlay {
                if recentlyDeletedViewModel.songs.count >= 1 {
                    VStack {
                        Spacer()
                        ZStack {
                            VisualEffectBlur(blurStyle: .systemMaterial)
                                .mask(LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.clear]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                ))
                                .edgesIgnoringSafeArea(.all)
                            Button {
                                showDeleteAllConfirmation = true
                            } label: {
                                HStack(spacing: 7) {
                                    FAText(iconName: "trash-can", size: 18)
                                    Text("Delete All")
                                }
                                .padding(15)
                                .background(Color.red.opacity(0.9))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .shadow(color: .red, radius: 20, x: 6, y: 6)
                                .padding()
                            }
                            .alert(isPresented: $showDeleteAllConfirmation) {
                                Alert(title: Text("delete_all_recently_deleted_songs"), message: Text("action_cannot_be_undone"), primaryButton: .destructive(Text("Delete All"), action: {recentlyDeletedViewModel.deleteAllSongs()}), secondaryButton: .cancel())
                            }
                        }
                        .frame(height: 80)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            recentlyDeletedViewModel.fetchRecentlyDeletedSongs()
        }
    }
}

#Preview {
    NavigationView {
        RecentlyDeletedView()
            .onAppear {
                RecentlyDeletedViewModel.shared.isLoadingSongs = false
                RecentlyDeletedViewModel.shared.songs.append(RecentlyDeletedSong(uid: "", timestamp: Date.distantPast, deletedTimestamp: Date.distantFuture, title: "Test", lyrics: ""))
            }
    }
}
