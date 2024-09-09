//
//  DemoAttachment.swift
//  Lyrics
//
//  Created by Liam Willey on 9/8/24.
//

import SwiftUI

struct DemoAttachment: Identifiable {
    var id = UUID()
    let title: String
    let icon: String
    let color: Color
    let url: String
}
