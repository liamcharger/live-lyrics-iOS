//
//  TaggedSongsView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/5/24.
//

import SwiftUI

struct TaggedSongsView: View {
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel()
    
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    @StateObject var authViewModel = AuthViewModel()
    
    @State var isRedSongsCollapsed = false
    @State var isGreenSongsCollapsed = false
    @State var isOrangeSongsCollapsed = false
    @State var isYellowSongsCollapsed = false
    @State var isBlueSongsCollapsed = false
    
    @State private var selectedSong: Song?
    @State private var showDeleteSheet = false
    
    func searchableSongs(for selection: TagSelectionEnum) -> [Song] {
        let selectedColor = selection.rawValue
        
        switch selection {
        case .red, .green, .orange, .yellow, .blue:
            return mainViewModel.songs.filter { song in
                if let colors = song.tags {
                    return colors.contains(selectedColor)
                } else {
                    return false
                }
            }
        }
    }
    func isShown(with tag: TagSelectionEnum) -> Bool {
        switch tag {
        case .red:
            return isRedSongsCollapsed
        case .green:
            return isGreenSongsCollapsed
        case .orange:
            return isOrangeSongsCollapsed
        case .yellow:
            return isYellowSongsCollapsed
        case .blue:
            return isBlueSongsCollapsed
        }
    }

    init() {
        mainViewModel.fetchSongs()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                CustomNavBar(title: "Tagged", navType: .Auth, folder: nil, showBackButton: true, isEditing: .constant(false))
            }
            .padding(.top)
            .padding(.horizontal)
            .padding(.bottom, 12)
            Divider()
            ScrollView {
                VStack {
                    if storeKitManager.purchasedProducts.isEmpty {
                        AdBannerView(unitId: "ca-app-pub-5671219068273297/6110262484", height: 50)
                            .padding(.bottom, 10)
                    }
                    if !mainViewModel.isLoadingSongs {
                        ForEach(TagSelectionEnum.allTags, id: \.self) { tag in
                            let tagTitle = tag.rawValue.capitalized
                            
                            VStack {
                                HStack(spacing: 3) {
                                    ListHeaderView(title: tagTitle)
                                    Spacer()
                                    Button {
                                        withAnimation(.bouncy(extraBounce: 0.1)) {
                                            switch tag {
                                            case .red:
                                                isRedSongsCollapsed.toggle()
                                            case .green:
                                                isGreenSongsCollapsed.toggle()
                                            case .orange:
                                                isOrangeSongsCollapsed.toggle()
                                            case .yellow:
                                                isYellowSongsCollapsed.toggle()
                                            case .blue:
                                                isBlueSongsCollapsed.toggle()
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "chevron.down")
                                            .padding(13.5)
                                            .foregroundColor(Color.blue)
                                            .background(Material.regular)
                                            .clipShape(Circle())
                                            .font(.system(size: 18).weight(.medium))
                                    }
                                    .rotationEffect(Angle(degrees: isShown(with: tag) ? 90 : 0))
                                }
                                if !isShown(with: tag) {
                                    let songs = searchableSongs(for: tag)
                                    
                                    ForEach(songs, id: \.id) { song in
                                        if song.title == "noSongs" {
                                            Text("No Songs")
                                                .foregroundColor(Color.gray)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .deleteDisabled(true)
                                                .moveDisabled(true)
                                        } else {
                                            NavigationLink(destination: SongDetailView(song: song, songs: songs, restoreSong: nil, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", folder: nil), label: {
                                                ListRowView(isEditing: .constant(false), title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "thumbtack" : "", icon: nil, subtitleForSong: song)
                                            })
                                        }
                                    }
                                }
                            }
                            .padding(.bottom)
                        }
                    } else {
                        LoadingView()
                    }
                }
                .padding(.top)
                .padding(.horizontal)
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    TaggedSongsView()
}
