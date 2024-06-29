//
//  MusixmatchService.swift
//  Lyrics
//
//  Created by Liam Willey on 6/27/24.
//

import Foundation

class MusixmatchService: ObservableObject {
    @Published var popularSongs = [Track]()
    @Published var searchedSongs = [Track]()
    @Published var popularArtists = [Artist]()
    
    @Published var isLoadingPopularSongs = true
    @Published var isLoadingPopularArtists = true
    // Used when song detail view is opened by user
    @Published var isLoadingSong = true
    // Used for songs searched by user
    @Published var isLoadingSongs = false
    
    private static let endpoint: String = "https://api.musixmatch.com/ws/1.1/"
    private static let apiKey: String = "b26ca438b52fdba4a6c276cacbf6ef43"
    
    static let shared = MusixmatchService()
    
    func requestPopularSongs() {
        var components = URLComponents(string: MusixmatchService.endpoint + "chart.tracks.get")
        
        components?.queryItems = [
            URLQueryItem(name: "chart_name", value: "top"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: "6"),
            URLQueryItem(name: "f_has_lyrics", value: "1"),
            URLQueryItem(name: "apikey", value: MusixmatchService.apiKey)
        ]
        
        guard let url = components?.url else {
            print("Invalid URL.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned.")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let musixmatchResponse = try decoder.decode(SongResponse.self, from: data)
                
                for track in musixmatchResponse.message.body.trackList {
                    DispatchQueue.main.async {
                        self.popularSongs.append(track.track)
                    }
                }
                
                DispatchQueue.main.async {
                    self.isLoadingPopularSongs = false
                }
            } catch let decodingError {
                print("Error decoding JSON for popular songs: \(decodingError.localizedDescription)")
            }
        }.resume()
    }
    
    func requestPopularArtists() {
        var components = URLComponents(string: MusixmatchService.endpoint + "chart.artists.get")
        components?.queryItems = [
            URLQueryItem(name: "chart_name", value: "top"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: "8"),
            URLQueryItem(name: "apikey", value: MusixmatchService.apiKey)
        ]
        guard let url = components?.url else {
            print("Invalid URL.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned.")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ArtistResponse.self, from: data)
                
                for artist in response.message.body.artist_list {
                    DispatchQueue.main.async {
                        self.popularArtists.append(artist.artist)
                    }
                }
                
                DispatchQueue.main.async {
                    self.isLoadingPopularArtists = false
                }
            } catch let decodingError {
                print("Error decoding JSON for popular artists: \(decodingError.localizedDescription)")
            }
        }.resume()
    }
    
    func fetchLyrics(forTrackId trackId: Int, completion: @escaping(Lyrics) -> Void) {
        var components = URLComponents(string: MusixmatchService.endpoint + "track.lyrics.get")
        components?.queryItems = [
            URLQueryItem(name: "track_id", value: String(trackId)),
            URLQueryItem(name: "apikey", value: MusixmatchService.apiKey)
        ]
        guard let url = components?.url else {
            print("Invalid URL.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned.")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(LyricsResponse.self, from: data)
                
                completion(response.message.body.lyrics)
                
                DispatchQueue.main.async {
                    self.isLoadingSong = false
                }
            } catch let decodingError {
                print("Error decoding JSON for song lyrics: \(decodingError.localizedDescription)")
            }
        }.resume()
    }
    
    func searchForSongs(_ query: String) {
        self.isLoadingSongs = true
        
        var components = URLComponents(string: MusixmatchService.endpoint + "track.search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "f_has_lyrics", value: "1"),
            URLQueryItem(name: "apikey", value: MusixmatchService.apiKey)
        ]
        guard let url = components?.url else {
            print("Invalid URL.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned.")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(SongResponse.self, from: data)
                
                for track in response.message.body.trackList {
                    self.searchedSongs.append(track.track)
                }
                
                DispatchQueue.main.async {
                    self.isLoadingSongs = false
                }
            } catch let decodingError {
                print("Error decoding JSON while searching for songs: \(decodingError.localizedDescription)")
            }
        }.resume()
    }
}
