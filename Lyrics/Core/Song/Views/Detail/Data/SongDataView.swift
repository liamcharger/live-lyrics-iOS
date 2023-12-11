//
//  SongDataView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/15/23.
//

import SwiftUI

struct SongDataView: View {
    // Environment & Object vars
    @Environment(\.presentationMode) var presMode
    @ObservedObject var songDetailViewModel = SongDetailViewModel()
    
    // Let vars
    let albumData: AlbumDetailsResponse?
    let song: Song
    
    // State vars
    @State var artistData: ArtistDetailsResponse?
    @State var isArtistCollapsed = false
    @State var isAlbumCollapsed = false
    
    var body: some View {
        VStack {
            // MARK: Navbar
            HStack(alignment: .center, spacing: 10) {
                Text("Info")
                    .font(.title2.weight(.bold))
                Spacer()
                Button(action: {presMode.wrappedValue.dismiss()}) {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color("Color"))
                        .background(Material.regular)
                        .clipShape(Circle())
                }
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // MARK: Listen on text elements
                    if let albumData = albumData {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                if let spotifyIds = albumData.message.body.album.externalIds.spotify as? [String] {
                                    if let mainReleaseId = spotifyIds.first {
                                        if let spotifyUrl = URL(string: "https://open.spotify.com/album/\(mainReleaseId)") {
                                            Link("Listen on Spotify", destination: spotifyUrl)
                                                .padding(12)
                                                .foregroundColor(.green)
                                                .background(Material.regular)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                
                                if let itunesIds = albumData.message.body.album.externalIds.itunes as? [String] {
                                    // Find the main release by filtering the iTunes IDs
                                    if let mainReleaseId = itunesIds.first {
                                        if let appleMusicURL = URL(string: "https://music.apple.com/album/\(mainReleaseId)") {
                                            Link("Listen on Apple Music", destination: appleMusicURL)
                                                .padding(12)
                                                .foregroundColor(.red)
                                                .background(Material.regular)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                
                                if let amazonMusic = albumData.message.body.album.externalIds.amazonMusic as? [String] {
                                    ForEach(amazonMusic, id: \.self) { id in
                                        Button {
                                            
                                        } label: {
                                            Text("Listen on Amazon Music")
                                                .padding(12)
                                                .foregroundColor(.purple)
                                                .background(Material.regular)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }
                    // MARK: Artist
                    VStack {
                        VStack {
                            HStack {
                                Text("Artist")
                                    .font(.body.weight(.semibold))
                                Spacer()
                                Button {
                                    isArtistCollapsed.toggle()
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .padding(12)
                                        .background(Material.regular)
                                        .clipShape(Circle())
                                        .rotationEffect(.degrees(isArtistCollapsed ? 90 : 0))
                                }
                                .foregroundColor(.primary)
                            }
                            if !isArtistCollapsed {
                                Divider()
                                    .padding(.horizontal, -15)
                            }
                        }
                        .padding(!isArtistCollapsed ? [.top, .horizontal] : .all, 12)
                        .padding(.bottom, !isArtistCollapsed ? -12 : 1)
                        if let albumData = albumData {
                            if !isArtistCollapsed {
                                VStack(spacing: 12) {
                                    SongDataRowView(title: "Name", subtitle: albumData.message.body.album.artistName)
                                    if let artistRating = artistData?.message.body.artist.artistRating {
                                        Divider()
                                        SongDataRowView(title: "Rating", subtitle: "\(artistRating)%")
                                    }
                                }
                                .padding()
                            }
                        } else {
                            if !isArtistCollapsed {
                                VStack(spacing: 12) {
                                    SongDataRowView(title: "Name", subtitle: artistData?.message.body.artist.artistName ?? "Not Available")
                                    if let artistRating = artistData?.message.body.artist.artistRating {
                                        Divider()
                                        SongDataRowView(title: "Rating", subtitle: "\(artistData?.message.body.artist.artistRating ?? 0)")
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .background {
                        Rectangle()
                            .fill(.clear)
                            .background(Material.regular)
                            .mask { RoundedRectangle(cornerRadius: 10, style: .continuous) }
                    }
                    // MARK: Album
                    if let albumData = albumData {
                        VStack {
                            VStack {
                                VStack {
                                    HStack {
                                        Text("Album")
                                            .font(.body.weight(.semibold))
                                        Spacer()
                                        Button {
                                            isAlbumCollapsed.toggle()
                                        } label: {
                                            Image(systemName: "chevron.down")
                                                .padding(12)
                                                .background(Material.regular)
                                                .clipShape(Circle())
                                                .rotationEffect(.degrees(isAlbumCollapsed ? 90 : 0))
                                        }
                                        .foregroundColor(.primary)
                                    }
                                    if !isAlbumCollapsed {
                                        Divider()
                                            .padding(.horizontal, -12)
                                    }
                                }
                                .padding(!isAlbumCollapsed ? [.top, .horizontal] : .all, 12)
                                .padding(.bottom, !isAlbumCollapsed ? -12 : 1)
                            }
                            if !isAlbumCollapsed {
                                VStack(spacing: 14) {
                                    SongDataRowView(title: "Name", subtitle: albumData.message.body.album.albumName)
                                    Divider()
                                    SongDataRowView(title: "Release Date", subtitle: albumData.message.body.album.albumReleaseDate)
                                    Divider()
                                    HStack {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("Copyright")
                                            Text(albumData.message.body.album.albumPline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                }
                                .padding()
                            }
                        }
                        .background {
                            Rectangle()
                                .fill(.clear)
                                .background(Material.regular)
                                .mask { RoundedRectangle(cornerRadius: 10, style: .continuous) }
                        }
                    }
                }
                .animation(.bouncy)
            }
        }
        .padding([.leading, .top, .trailing])
        .onAppear {
            if let albumData = albumData {
                self.songDetailViewModel.fetchArtistDetails(artistId: albumData.message.body.album.artistId) { result in
                    switch result {
                    case .success(let artistData):
                        self.artistData = artistData
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
}
