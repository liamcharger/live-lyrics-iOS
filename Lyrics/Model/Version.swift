//
//  Version.swift
//  Lyrics
//
//  Created by Liam Willey on 4/17/24.
//

import Foundation

struct Version: Comparable {
    let versionComponents: [Int]
    
    init?(_ versionString: String) {
        let components = versionString.split(separator: ".").compactMap { Int($0) }
        guard !components.isEmpty else { return nil }
        versionComponents = components
    }
    
    static func < (lhs: Version, rhs: Version) -> Bool {
        for (left, right) in zip(lhs.versionComponents, rhs.versionComponents) {
            if left != right {
                return left < right
            }
        }
        return lhs.versionComponents.count < rhs.versionComponents.count
    }
    
    static func == (lhs: Version, rhs: Version) -> Bool {
        lhs.versionComponents == rhs.versionComponents
    }
}
