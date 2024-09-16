//
//  DatamuseWordRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/31/24.
//

import SwiftUI

struct DatamuseWordRowView: View {
    let word: String
    
    @Binding var selectedWord: DatamuseWord?
    
    var body: some View {
        if let selectedWord = selectedWord, selectedWord.word == word {
            Image(systemName: "checkmark")
                .font(.body.weight(.medium))
                .modifier(DatamuseWordRowViewModifier())
        } else {
            Text(word)
                .modifier(DatamuseWordRowViewModifier())
        }
    }
}

struct DatamuseWordRowViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Material.thin)
            .foregroundColor(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
