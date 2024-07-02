//
//  Band.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import Foundation
import FirebaseFirestoreSwift

struct Band: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    // Used by user to join a band
    let joinId: String
    let members: [String]
    // Should there be global notes?
    // let notes: String
}
