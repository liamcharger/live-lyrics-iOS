//
//  Notification.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import Foundation
import SwiftUI

struct Notification: Identifiable, Codable {
    var id = UUID()
    var title: String
    var body: String
    var imageName: String?
}
