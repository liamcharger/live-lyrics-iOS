//
//  Take.swift
//  Lyrics
//
//  Created by Liam Willey on 4/22/24.
//

import Foundation

struct Take: Identifiable, Codable, Equatable {
    var id = UUID()
    var url: URL
    var date: Date
    var title: String?
    
    static func == (lhs: Take, rhs: Take) -> Bool {
        return lhs.id == rhs.id
    }
}
