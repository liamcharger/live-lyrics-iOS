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
    
    static let defaultId = "d45234543e542354f453254a45435u54325432543l54214354t643254325432"
}
