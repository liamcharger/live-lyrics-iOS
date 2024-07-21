//
//  Song.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct SharedFolder: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let from: String
    let folderId: String
    var order: Int?
    var readOnly: Bool?
    var songVariations: [String]?
    var bandId: String?
}
