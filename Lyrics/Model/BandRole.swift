//
//  BandRole.swift
//  Lyrics
//
//  Created by Liam Willey on 7/2/24.
//

import Foundation
import FirebaseFirestoreSwift

struct BandRole: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let color: String
    let icon: String
}
