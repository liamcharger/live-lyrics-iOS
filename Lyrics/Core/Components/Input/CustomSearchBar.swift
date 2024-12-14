//
//  CustomSearchBar.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

struct CustomSearchBar: View {
    @Binding var text: String
    
    let placeholder: String
    
    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField(placeholder, text: $text)
            }
            .padding(12)
            .background(Material.regular)
            .clipShape(Capsule())
        }
    }
}
