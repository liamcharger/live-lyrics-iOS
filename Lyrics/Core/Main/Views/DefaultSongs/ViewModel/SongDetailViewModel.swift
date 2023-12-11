//
//  SongDetailViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 8/11/23.
//

import Foundation
import SwiftUI
import Combine
import Alamofire

class SongDetailViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    var searchResults = [SearchTrack]()
    var tracks = [Track]()
    @Published var lyrics = ""
    @Published var isLoading = true
    @Published var song: Track?
    
    init() {
        fetchTracks()
    }
    
    func fetchTracks() {
        let urlString = "https://api.musixmatch.com/ws/1.1/chart.tracks.get?page=1&page_size=10&country=us&apikey=\(apiKey)"
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(TrackListResponse.self, from: data)
                        let tracks = response.message.body.track_list.map { $0.track }
                        
                        DispatchQueue.main.async {
                            self.tracks = tracks
                            self.isLoading = false
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }
            }.resume()
        }
    }
    
    func fetchAlbumDetails(albumId: Int, completion: @escaping (Result<AlbumDetailsResponse, Error>) -> Void) {
        let urlString = "https://api.musixmatch.com/ws/1.1/album.get?album_id=\(albumId)&apikey=\(apiKey)"

        AF.request(urlString).responseDecodable(of: AlbumDetailsResponse.self) { response in
            switch response.result {
            case .success(let albumDetailsResponse):
                    print(albumDetailsResponse)
                    completion(.success(albumDetailsResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchArtistDetails(artistId: Int, completion: @escaping (Result<ArtistDetailsResponse, Error>) -> Void) {
        let urlString = "https://api.musixmatch.com/ws/1.1/artist.get?artist_id=\(artistId)&apikey=\(apiKey)"

        AF.request(urlString).responseDecodable(of: ArtistDetailsResponse.self) { response in
            switch response.result {
            case .success(let artistDetailsResponse):
                print(artistDetailsResponse)
                completion(.success(artistDetailsResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func searchSongs(trackName: String, artist: String) {
        let formattedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let formattedTrackName = trackName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.musixmatch.com/ws/1.1/track.search?q_artist=\(formattedArtist)&q_track=\(formattedTrackName)&apikey=\(apiKey)"
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
                        let trackList = response.message.body.track_list
                        
                        DispatchQueue.main.async {
                            self.searchResults = trackList
                            self.isLoading = false
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }
            }.resume()
        }
    }
    
    func fetchLyrics(trackId: Int, completion: @escaping(Bool, String) -> Void) {
        let urlString = "https://api.musixmatch.com/ws/1.1/track.lyrics.get?track_id=\(trackId)&apikey=\(apiKey)"

        AF.request(urlString).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any],
                   let message = json["message"] as? [String: Any],
                   let body = message["body"] as? [String: Any],
                   let lyrics = body["lyrics"] as? [String: Any],
                   let lyricsBody = lyrics["lyrics_body"] as? String {
                    self.lyrics = lyricsBody
                    completion(true, "")
                } else {
                    self.lyrics = ""
                    completion(false, "It looks like no one has added any lyrics to this song.")
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
