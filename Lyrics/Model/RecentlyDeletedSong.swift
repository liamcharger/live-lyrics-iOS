//
//  Song.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct RecentlyDeletedSong: Identifiable, Codable {
    @DocumentID var id: String?
    let uid: String
    let timestamp: Date
    let folderId: String?
    let deletedTimestamp: Date
    var title: String
    var lyrics: String
    var order: Int?
    var size: Int?
    var key: String?
    var notes: String?
    var weight: Double?
    var alignment: Double?
    var design: Double?
    var lineSpacing: Double?
    var artist: String?
    var bpm: String?
    var pinned: Bool?
    var songId: Int?
    var performanceView: Bool?
    var enableAutoscroll: Bool?
    var duration: Int?
    var autoscrollDuration: String?
}
