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
    // For checking whether the parsed folder is a SharedFolder or not
    var isSharedFolder: Bool?
}
