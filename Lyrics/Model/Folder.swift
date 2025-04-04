//
//  Song.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct Folder: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let uid: String?
    let timestamp: Date
    var title: String
    var order: Int
    var readOnly: Bool?
    var notes: String?
    var joinedUsers: [String]?
    var songVariations: [String]?
    var bandId: String?
}
