//
//  Responses.swift
//  Lyrics
//
//  Created by Liam Willey on 8/11/23.
//

import Foundation

let apiKey = "b26ca438b52fdba4a6c276cacbf6ef43"

// MARK: Enums
enum NetworkError: Error {
    case invalidResponse
}

// MARK: Artist
struct ArtistDetailsResponse: Codable {
    let message: ArtistDetailsMessage
}

struct ArtistDetailsMessage: Codable {
    let header: ArtistDetailsHeader
    let body: ArtistDetailsBody
}

struct ArtistDetailsHeader: Codable {
    let statusCode: Int
    let executeTime: Double
    
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case executeTime = "execute_time"
    }
}

struct ArtistDetailsBody: Codable {
    let artist: ArtistDetails
}

struct ArtistDetails: Codable {
    let artistId: Int
    let artistName: String
    let artistNameTranslationList: [String]?
    let artistComment: String
    let artistCountry: String
    let artistAliasList: [String]
    let artistRating: Int
    let artistTwitterURL: String
    let artistCredits: ArtistCredits
    let restricted: Int
    let updatedTime: String
    let beginDateYear: String
    let beginDate: String
    let endDateYear: String
    let endDate: String
    
    enum CodingKeys: String, CodingKey {
        case artistId = "artist_id"
        case artistName = "artist_name"
        case artistNameTranslationList = "artist_name_translation_list"
        case artistComment = "artist_comment"
        case artistCountry = "artist_country"
        case artistAliasList = "artist_alias_list"
        case artistRating = "artist_rating"
        case artistTwitterURL = "artist_twitter_url"
        case artistCredits = "artist_credits"
        case restricted = "restricted"
        case updatedTime = "updated_time"
        case beginDateYear = "begin_date_year"
        case beginDate = "begin_date"
        case endDateYear = "end_date_year"
        case endDate = "end_date"
    }
}

struct ArtistCredits: Codable {
    let artistList: [ArtistCredit]
    
    enum CodingKeys: String, CodingKey {
        case artistList = "artist_list"
    }
}

struct ArtistCredit: Codable {
    // Define properties for artist credits if needed
    // Example: let artistId: Int
}


// MARK: Album
struct AlbumDetailsResponse: Codable {
    let message: AlbumMessage
}

struct AlbumMessage: Codable {
    let header: AlbumHeader
    let body: AlbumBody
}

struct AlbumHeader: Codable {
    let statusCode: Int
    let executeTime: Double

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case executeTime = "execute_time"
    }
}

struct AlbumBody: Codable {
    let album: AlbumInfo
}

struct AlbumInfo: Codable {
    let albumId: Int
    let albumName: String
    let albumRating: Int
    let albumReleaseDate: String
    let artistId: Int
    let artistName: String
    let primaryGenres: GenreList
    let secondaryGenres: GenreList?
    let albumPline: String
    let albumCopyright: String
    let updatedTime: String
    let externalIds: ExternalIds

    enum CodingKeys: String, CodingKey {
        case albumId = "album_id"
        case albumName = "album_name"
        case albumRating = "album_rating"
        case albumReleaseDate = "album_release_date"
        case artistId = "artist_id"
        case artistName = "artist_name"
        case primaryGenres = "primary_genres"
        case secondaryGenres = "secondary_genres"
        case albumPline = "album_pline"
        case albumCopyright = "album_copyright"
        case updatedTime = "updated_time"
        case externalIds = "external_ids"
    }
}

struct ExternalIds: Codable {
    let spotify: [String]
    let itunes: [String]
    let amazonMusic: [String]?

    enum CodingKeys: String, CodingKey {
        case spotify
        case itunes
        case amazonMusic = "amazon_music"
    }
}

struct GenreList: Codable {
    let musicGenreList: [Genre]

    enum CodingKeys: String, CodingKey {
        case musicGenreList = "music_genre_list"
    }
}

struct Genre: Codable {
    let musicGenre: GenreDetails

    enum CodingKeys: String, CodingKey {
        case musicGenre = "music_genre"
    }
}

struct GenreDetails: Codable {
    let musicGenreId: Int
    let musicGenreParentId: Int
    let musicGenreName: String
    let musicGenreNameExtended: String

    enum CodingKeys: String, CodingKey {
        case musicGenreId = "music_genre_id"
        case musicGenreParentId = "music_genre_parent_id"
        case musicGenreName = "music_genre_name"
        case musicGenreNameExtended = "music_genre_name_extended"
    }
}

// MARK: Track
struct TrackListResponse: Codable {
    let message: TrackListMessage
}

struct TrackListMessage: Codable {
    let header: TrackListHeader
    let body: TrackListBody
}

struct TrackListHeader: Codable {
    let status_code: Int
    let execute_time: Double
}

struct TrackListBody: Codable {
    let track_list: [TrackListItem]
}

struct TrackListItem: Codable {
    let track: Track
}

struct SongDetailResponse: Codable {
    let message: Message
}

struct Message: Codable {
    let body: Body
}

struct Body: Codable {
    let track: Track
}

struct Track: Codable {
    let track_id: Int
    let track_name: String
    let artist_name: String
    let album_name: String
    let commontrack_id: Int
    let instrumental: Int
    let explicit: Int
    let has_lyrics: Int
    let has_subtitles: Int
    let has_richsync: Int
    let num_favourite: Int
    let album_id: Int
    let track_share_url: String
    let track_edit_url: String
    let restricted: Int
    let updated_time: String
    let primary_genres: PrimaryGenres
}

struct PrimaryGenres: Codable {
    let music_genre_list: [MusicGenre]
}

struct MusicGenre: Codable {
    let music_genre: GenreDetail
}

struct GenreDetail: Codable {
    let music_genre_id: Int
    let music_genre_parent_id: Int
    let music_genre_name: String
    let music_genre_name_extended: String
    let music_genre_vanity: String
}

struct SearchResponse: Codable {
    let message: SearchMessage
}

struct SearchMessage: Codable {
    let header: SearchHeader
    let body: SearchBody
}

struct SearchHeader: Codable {
    let status_code: Int
    let execute_time: Double
    let available: Int
}

struct SearchBody: Codable {
    let track_list: [SearchTrack]
}

struct SearchTrack: Codable {
    let track: Track
}

struct LyricsResponse: Decodable {
    let message: LyricsMessage
}

struct LyricsMessage: Decodable {
    let body: [LyricsBody]
}

struct LyricsBody: Decodable {
    let lyrics: Lyrics
}

struct Lyrics: Decodable {
    let lyrics_id: Int
    let restricted: Int
    let instrumental: Int
    let lyrics_body: String
    let lyrics_language: String
    let script_tracking_url: String
    let pixel_tracking_url: String
    let lyrics_copyright: String
    let backlink_url: String
    let updated_time: String
}
