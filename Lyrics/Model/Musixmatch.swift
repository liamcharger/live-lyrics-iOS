//
//  Musixmatch.swift
//  Lyrics
//
//  Created by Liam Willey on 6/27/24.
//

import Foundation

struct SongResponse: Codable {
    let message: Message
    
    struct Message: Codable {
        let header: Header
        let body: Body
        
        struct Header: Codable {
            let statusCode: Int
            let executeTime: Double
            
            enum CodingKeys: String, CodingKey {
                case statusCode = "status_code"
                case executeTime = "execute_time"
            }
        }
        
        struct Body: Codable {
            let trackList: [TrackListItem]
            
            struct TrackListItem: Codable {
                let track: Track
            }
            
            enum CodingKeys: String, CodingKey {
                case trackList = "track_list"
            }
        }
    }
}

struct Track: Codable {
    let trackId: Int
    let trackName: String
    let trackNameTranslationList: [TrackNameTranslation]
    let trackRating: Int
    let commontrackId: Int
    let instrumental: Int
    let explicit: Int
    let hasLyrics: Int
    let hasSubtitles: Int
    let hasRichsync: Int
    let numFavourite: Int
    let albumId: Int
    let albumName: String
    let artistId: Int
    let artistName: String
    let trackShareURL: String
    let trackEditURL: String
    let restricted: Int
    let updatedTime: String
    let primaryGenres: PrimaryGenres
    
    enum CodingKeys: String, CodingKey {
        case trackId = "track_id"
        case trackName = "track_name"
        case trackNameTranslationList = "track_name_translation_list"
        case trackRating = "track_rating"
        case commontrackId = "commontrack_id"
        case instrumental
        case explicit
        case hasLyrics = "has_lyrics"
        case hasSubtitles = "has_subtitles"
        case hasRichsync = "has_richsync"
        case numFavourite = "num_favourite"
        case albumId = "album_id"
        case albumName = "album_name"
        case artistId = "artist_id"
        case artistName = "artist_name"
        
        case trackShareURL = "track_share_url"
        case trackEditURL = "track_edit_url"
        case restricted
        case updatedTime = "updated_time"
        case primaryGenres = "primary_genres"
    }
}

struct TrackNameTranslation: Codable {
    let trackNameTranslation: TrackNameTranslationItem
    
    enum CodingKeys: String, CodingKey {
        case trackNameTranslation = "track_name_translation"
    }
}

struct TrackNameTranslationItem: Codable {
    let language: String
    let translation: String
}

struct PrimaryGenres: Codable {
    let musicGenreList: [MusicGenreListItem]
    
    enum CodingKeys: String, CodingKey {
        case musicGenreList = "music_genre_list"
    }
}

struct MusicGenreListItem: Codable {
    let musicGenre: MusicGenre
    
    enum CodingKeys: String, CodingKey {
        case musicGenre = "music_genre"
    }
}

struct MusicGenre: Codable {
    let musicGenreId: Int
    let musicGenreParentId: Int
    let musicGenreName: String
    let musicGenreNameExtended: String
    let musicGenreVanity: String
    
    enum CodingKeys: String, CodingKey {
        case musicGenreId = "music_genre_id"
        case musicGenreParentId = "music_genre_parent_id"
        case musicGenreName = "music_genre_name"
        case musicGenreNameExtended = "music_genre_name_extended"
        case musicGenreVanity = "music_genre_vanity"
    }
}

struct ArtistResponse: Codable {
    let message: Message
    
    struct Message: Codable {
        let header: Header
        let body: Body
        
        struct Body: Codable {
            let artist_list: [ArtistItem]
            
            struct ArtistItem: Codable, Identifiable {
                let artist: Artist
                
                var id: Int {
                    return artist.artist_id
                }
            }
        }
        
        struct Header: Codable {
            let status_code: Int
            let execute_time: Double
        }
    }
}

struct Artist: Codable {
    let artist_id: Int
    let artist_name: String
    let artist_name_translation_list: [ArtistNameTranslation]
    let artist_alias_list: [ArtistAlias]
    let artist_rating: Int
    let artist_twitter_url: String?
    let restricted: Int
    let updated_time: String
    
    struct ArtistNameTranslation: Codable {
        let artist_name_translation: ArtistNameTranslationDetail
    }
    
    struct ArtistNameTranslationDetail: Codable {
        let language: String
        let translation: String
    }
    
    struct ArtistAlias: Codable {
        let artist_alias: String
    }
}

struct Lyrics: Codable {
    let lyrics_id: Int
    let explicit: Int
    let lyrics_body: String
    let script_tracking_url: String
    let pixel_tracking_url: String
    let lyrics_copyright: String
    let updated_time: String
}

struct LyricsResponse: Codable {
    let message: Message
    
    struct Message: Codable {
        let body: Body
        
        struct Body: Codable {
            let lyrics: Lyrics
        }
    }
}

struct AlbumResponse: Codable {
    let message: Message
    
    struct Message: Codable {
        let body: Body
        
        struct Body: Codable {
            let album: Album
        }
    }
}

struct Album: Codable {
    let albumId: Int
//    let albumMbid: String
    let albumName: String
    let albumRating: Int
//    let albumTrackCount: Int
    let albumReleaseDate: String
//    let albumReleaseType: String
//    let artistId: Int
//    let artistName: String
//    let primaryGenres: [MusicGenre]
//    let secondaryGenres: [MusicGenre]
    let albumPline: String
    let albumCopyright: String
    let albumLabel: String
//    let albumVanityId: String
//    let albumEditUrl: String
    let restricted: Int
    let updatedTime: String
    let externalIds: ExternalIds
//    let albumCoverart100x100: String
//    let albumCoverart350x350: String
//    let albumCoverart500x500: String
//    let albumCoverart800x800: String
    
    enum CodingKeys: String, CodingKey {
        case albumId = "album_id"
//        case albumMbid = "album_mbid"
        case albumName = "album_name"
        case albumRating = "album_rating"
//        case albumTrackCount = "album_track_count"
        case albumReleaseDate = "album_release_date"
//        case albumReleaseType = "album_release_type"
//        case artistId = "artist_id"
//        case artistName = "artist_name"
//        case primaryGenres = "primary_genres"
//        case secondaryGenres = "secondary_genres"
        case albumPline = "album_pline"
        case albumCopyright = "album_copyright"
        case albumLabel = "album_label"
//        case albumVanityId = "album_vanity_id"
//        case albumEditUrl = "album_edit_url"
        case restricted
        case updatedTime = "updated_time"
        case externalIds = "external_ids"
//        case albumCoverart100x100 = "album_coverart_100x100"
//        case albumCoverart350x350 = "album_coverart_350x350"
//        case albumCoverart500x500 = "album_coverart_500x500"
//        case albumCoverart800x800 = "album_coverart_800x800"
    }
}

struct ExternalIds: Codable {
    let spotify: [String]
    let itunes: [String]
    let amazonMusic: [String]
    
    enum CodingKeys: String, CodingKey {
        case spotify
        case itunes
        case amazonMusic = "amazon_music"
    }
}
