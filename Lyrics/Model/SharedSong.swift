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
    var order: Int
}
