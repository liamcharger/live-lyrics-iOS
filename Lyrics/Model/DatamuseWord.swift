//
//  DatamuseWord.swift
//  Lyrics
//
//  Created by Liam Willey on 8/30/24.
//

import Foundation

struct DatamuseWord: Identifiable, Codable {
    var id = UUID().uuidString
    let word: String
    let score: Int
}
