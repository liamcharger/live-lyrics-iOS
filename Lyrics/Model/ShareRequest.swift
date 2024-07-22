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
    var contentName: String
    var type: String
    var toUsername: [String]
    var fromUsername: String
    var songVariations: [String]?
    var readOnly: Bool?
    var notificationTokens: [String]?
}
