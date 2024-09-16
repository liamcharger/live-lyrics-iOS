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
    var uid: String
    let timestamp: Date
    var title: String
    var lyrics: String
    var order: Int?
    var size: Int?
    var key: String?
    var notes: String?
    var weight: Double?
    var alignment: Double?
    var lineSpacing: Double?
    var artist: String?
    var bpm: Int?
    var bpb: Int?
    var pinned: Bool?
    var performanceMode: Bool?
    var duration: String?
    var tags: [String]?
    var demoAttachments: [String]?
    
    var joinedUsers: [String]?
    var variations: [String]?
    var readOnly: Bool?
}
