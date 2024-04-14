//
//  ShareRequest.swift
//  Lyrics
//
//  Created by Liam Willey on 4/13/24.
//

import FirebaseFirestoreSwift
import Foundation

struct ShareRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var timestamp: Date
    var from: String
    var to: [String]
    var contentId: String
    var contentType: String
    var type: String
}
