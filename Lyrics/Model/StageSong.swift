//
//  StageSong.swift
//  Lyrics
//
//  Created by Liam Willey on 5/26/24.
//

import Foundation
import FirebaseFirestore

struct StageSong: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var artist: String
    var uid: String
}
