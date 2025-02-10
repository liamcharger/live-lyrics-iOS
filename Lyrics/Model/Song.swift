//
//  Song.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct Song: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    /// The user identifier of the user that created the song
    var uid: String
    /// The date when the song was created
    let timestamp: Date
    /// The date the song autoscroll timestamps were last updated
    let lastSynced: Date?
    /// The date the song was last updated
    let lastEdited: Date?
    /// The date the song lyrics were last edited
    let lastLyricsEdited: Date?
    let title: String
    let lyrics: String
    /// The current order of the song in the library/folder
    let order: Int?
    /// The song performance key (i.e., G, G#, D)
    let key: String?
    /// The notes assigned to the song
    let notes: String?
    /// The font size for the song's lyrics
    let size: Int?
    /// The font weight for the song's lyrics
    let weight: Double?
    /// The text alignment for the song's lyrics
    let alignment: Double?
    /// The line spacing for the song's lyrics
    let lineSpacing: Double?
    /// The artist of the song
    let artist: String?
    /// The number of beats per minute
    let bpm: Int?
    /// The number of beats per bar
    let bpb: Int?
    /// Whether the song is pinned in the user's library or not
    var pinned: Bool?
    /// Whether the song was last used with performance mode enabled or not
    var performanceMode: Bool?
    /// An array of tags assigned to the song
    let tags: [String]?
    /// An array of links to the song's demo attachments
    let demoAttachments: [String]?
    /// The identifier of the band that the song was shared through
    var bandId: String? // FIXME: can only handle one band at a time?
    /// An array of the synced lyric timestamps and their indexes (i.e, "3_4.5")
    let autoscrollTimestamps: [String]?
    /// An array of the users currently collaborating on the song
    let joinedUsers: [String]?
    ///  An array of variations allowed to be displayed to collaborating users
    var variations: [String]?
    /// Whether the song is read-only to a collaborating user or not
    var readOnly: Bool?
}
