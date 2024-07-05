//
//  BandMember.swift
//  Lyrics
//
//  Created by Liam Willey on 7/2/24.
//

import Foundation
import FirebaseFirestoreSwift

struct BandMember: Identifiable, Codable {
    @DocumentID var id: String?
    let uid: String
    let fullname: String
    let username: String
    let roleId: String?
}
