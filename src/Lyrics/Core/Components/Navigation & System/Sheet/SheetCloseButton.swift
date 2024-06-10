//
//  SheetCloseButton.swift
//  Lyrics
//
//  Created by Liam Willey on 10/24/23.
//

import SwiftUI

struct SheetCloseButton: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        Button(action: {isPresented = false}) {
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
    SheetCloseButton(isPresented: .constant(true))
}
