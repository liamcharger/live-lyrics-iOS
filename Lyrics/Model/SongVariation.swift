//
//  SongVariation.swift
//  Lyrics
//
//  Created by Liam Willey on 4/18/24.
//

import Foundation
import FirebaseFirestoreSwift

struct SongVariation: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var lyrics: String
    var songUid: String
    var songId: String
}
