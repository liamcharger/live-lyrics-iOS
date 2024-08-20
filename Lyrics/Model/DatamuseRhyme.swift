//
//  DatamuseRhyme.swift
//  Lyrics
//
//  Created by Liam Willey on 8/20/24.
//

import Foundation

struct DatamuseRhyme: Identifiable, Codable {
    let id = UUID().uuidString
    let word: String
    let score: Int
    let numSyllables: Int
}
