//
//  Song.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct SharedSong: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let from: String
    let songId: String
    var order: Int?
    var variations: [String]?
    var readOnly: Bool?
    var pinned: Bool?
    var performanceMode: Bool?
    var bandId: String?
}
