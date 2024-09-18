//
//  Rhyme.swift
//  Lyrics
//
//  Created by Liam Willey on 8/20/24.
//

import Foundation

struct RhymebrainRhyme: Decodable {
    let word: String
    let freq: Int
    let score: Int
    let flags: String
    let syllables: String
}

struct Rhyme: Decodable {
    let word: String
    let score: Int
    let syllables: Int
}
