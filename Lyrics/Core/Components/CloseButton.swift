//
//  CloseButton.swift
//  Lyrics
//
//  Created by Liam Willey on 10/24/23.
//

import SwiftUI

struct CloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .imageScale(.medium)
                .padding(12)
                .font(.body.weight(.semibold))
                .foregroundColor(.primary)
                .background(Material.regular)
                .clipShape(Circle())
        }
    }
}

#Preview {
    CloseButton(action: {})
}
