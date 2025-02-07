//
//  TagSelectionEnum.swift
//  Lyrics
//
//  Created by Liam Willey on 4/2/24.
//

import Foundation

enum TagSelectionEnum: String {
    case none = "none"
    case red = "red"
    case green = "green"
    case orange = "orange"
    case yellow = "yellow"
    case blue = "blue"
    
    static let allTags: [TagSelectionEnum] = [.red, .green, .orange, .yellow, .blue]
}
