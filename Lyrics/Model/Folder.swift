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
    // Use uid to check if the song is a shared song or not
    let uid: String?
    let timestamp: Date
    var title: String
    var order: Int
}
