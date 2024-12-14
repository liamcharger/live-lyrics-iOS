//
//  Notification.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import Foundation
import SwiftUI

struct Notification: Identifiable, Codable {
    enum `Type`: Codable {
        case info
        case notificationPrompt
    }
    
    var id = UUID()
    var title: String
    var body: String
    var imageName: String?
    var type: `Type`
    
    init(id: UUID = UUID(), title: String, body: String, imageName: String? = nil, type: `Type`? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.imageName = imageName
        self.type = type ?? .info
    }
}
