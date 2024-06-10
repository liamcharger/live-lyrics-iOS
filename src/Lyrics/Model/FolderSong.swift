//
//  FolderSong.swift
//  Lyrics
//
//  Created by Liam Willey on 4/16/24.
//

import Foundation
import FirebaseFirestoreSwift

struct FolderSong: Identifiable, Codable {
    @DocumentID var id: String?
    var order: Int
    var uid: String?
}
