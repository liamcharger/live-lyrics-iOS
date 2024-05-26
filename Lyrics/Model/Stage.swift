//
//  Stage.swift
//  Lyrics
//
//  Created by Liam Willey on 5/26/24.
//

import Foundation
import FirebaseFirestore

struct Stage: Identifiable, Codable {
    @DocumentID var id: String?
}
