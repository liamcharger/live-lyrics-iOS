//
//  ListEditButtonView.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

struct ListEditButtonView: View {
    @Binding var isEditing: Bool
    
    var body: some View {
        Text(isEditing ? "Done" : "Edit")
            .padding(12)
            .foregroundColor(Color.blue)
            .background(Material.regular)
            .clipShape(Capsule())
            .font(.footnote.weight(.bold))
    }
}

#Preview {
    ListEditButtonView(isEditing: .constant(true))
}
