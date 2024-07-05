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
    let joinId: String
    let members: [String]
    let admins: [String]
    // Should there be band-public notes?
    // let notes: String
}
