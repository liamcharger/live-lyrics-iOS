//
//  Song.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct RecentlyDeletedSong: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let uid: String
    let timestamp: Date
    let folderIds: [String]?
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
    var bpb: Int?
    var bpm: Int?
    var pinned: Bool?
    var performanceMode: Bool?
    var duration: String?
    var tags: [String]?
}
