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
    
    @State var text = ""
    
    @State var showMenu = false
    @State var showNewSong = false
    @State var isEditing = false
    @State var collapsedTitle = false
    @State var showDeleteAllConfirmation = false
    
    @State private var selectedSong: RecentlyDeletedSong?
    @State private var showDeleteSheet = false
    
    var recentlyDeletedSongs: [RecentlyDeletedSong] {
        return recentlyDeletedViewModel.songs.filter { song in
            return song.title != "noSongs"
        }
    }
    var searchableSongs: [RecentlyDeletedSong] {
        if text.isEmpty {
            return recentlyDeletedViewModel.songs
        } else {
            let lowercasedQuery = text.lowercased()
            return recentlyDeletedViewModel.songs.filter ({
                $0.title.lowercased().contains(lowercasedQuery)
            })
        }
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let song = recentlyDeletedViewModel.songs[index]
            recentlyDeletedViewModel.deleteSong(song: song)
        }
    }
    func performAction(for song: RecentlyDeletedSong) {
        selectedSong = song
        showDeleteSheet.toggle()
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                CustomNavBar(title: NSLocalizedString("recently_deleted", comment: ""), showBackButton: true, collapsed: .constant(false), collapsedTitle: $collapsedTitle)
                    .padding()
                Divider()
                ScrollView {
                    VStack(alignment: .leading) {
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollViewOffsetPreferenceKey.self, value: [geo.frame(in: .global).minY])
                        }
                        .frame(height: 0)
                        HeaderView("Recently \nDeleted", icon: "trash-can", color: .red, geo: geo, counter: "\(recentlyDeletedSongs.count) song\(recentlyDeletedSongs.count == 1 ? "" : "s")".uppercased())
                        AdBannerView(unitId: "ca-app-pub-5671219068273297/5562143788", height: 80, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0)
                        if !recentlyDeletedViewModel.isLoadingSongs {
                            if !searchableSongs.contains(where: { $0.title == "noSongs" }) {
                                Text("Deleted songs are stored for thirty days before being permanently removed.")
                                    .foregroundColor(Color.gray)
                                    .deleteDisabled(true)
                                    .padding(.horizontal, 10)
                                Divider()
                                    .padding(.horizontal, -16)
                            }
                            ForEach(searchableSongs, id: \.id) { song in
                                if song.title == "noSongs" {
                                    FullscreenMessage(imageName: "circle.slash", title: "You don't have any recently deleted songs.")
                                        .frame(maxWidth: .infinity)
                                        .frame(height: geo.size.height / 2.2, alignment: .bottom)
                                } else {
                                    let songData = Song(id: song.id ?? "", uid: song.uid, timestamp: song.timestamp, title: song.title, lyrics: song.lyrics, order: song.order)
                                    
                                    NavigationLink(destination: SongDetailView(song: songData, songs: nil, restoreSong: song, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", folder: nil), label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(song.title)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.gray)
                                            }
                                            let daysLeft = 30 - Calendar.current.dateComponents([.day], from: song.deletedTimestamp, to: Date()).day!
                                            if daysLeft <= 7 {
                                                Text("\(daysLeft) days")
                                                    .font(.body.weight(.semibold))
                                                    .foregroundColor(.red)
                                            }
                                            Text("\(song.deletedTimestamp.formatted())").foregroundColor(Color.gray)
                                        }
                                        .padding()
                                        .background(Material.regular)
                                        .foregroundColor(.primary)
                                        .cornerRadius(20)
                                        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 20))
                                        .contextMenu {
                                            Button {
                                                recentlyDeletedViewModel.restoreSong(song: song)
                                            } label: {
                                                Label("Restore", systemImage: "clock.arrow.circlepath")
                                            }
                                            Button(role: .destructive) {
                                                performAction(for: song)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    })
                                }
                            }
                        } else {
                            LoadingView()
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
                if recentlyDeletedSongs.count >= 1 {
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
                                .customShadow(color: .red, radius: 20, x: 6, y: 6)
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
            .environmentObject(AuthViewModel())
            .onAppear {
                RecentlyDeletedViewModel.shared.isLoadingSongs = false
                RecentlyDeletedViewModel.shared.songs.append(RecentlyDeletedSong(uid: "", timestamp: Date.distantPast, folderIds: [], deletedTimestamp: Date.distantFuture, title: "Test", lyrics: ""))
            }
    }
}
