//
//  ShareUser.swift
//  Lyrics
//
//  Created by Liam Willey on 7/6/24.
//

import Foundation
import FirebaseFirestoreSwift

struct ShareUser: Identifiable, Codable {
    @DocumentID var id: String?
    let uid: String
    let songVariations: [String]
    let fcmId: String?
}
