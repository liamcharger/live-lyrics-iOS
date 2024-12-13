//
//  CustomTextField.swift
//  Notes
//
//  Created by Liam Willey on 3/27/23.
//

import SwiftUI

struct CustomTextField: View {
    @Binding var text: String
    
    @FocusState var isFocused: Bool
    
    let placeholder: String
    let image: String?
    
    init(text: Binding<String>, placeholder: String, image: String? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.image = image
    }
    
    var body: some View {
        HStack(spacing: 7) {
            if let image {
                Image(systemName: image)
                    .foregroundStyle(.gray)
                    .frame(minWidth: 25)
            }
            TextField(NSLocalizedString(placeholder, comment: ""), text: $text)
                .focused($isFocused) // TODO: we need to check if this breaks any other focused properties applied outside the view
        }
        .padding(14)
        .background(Material.regular)
        .clipShape(Capsule())
        .onTapGesture {
            isFocused = true // Focuses the keyboard even if the material around the TextField is pressed
        }
    }
}

#Preview {
    CustomTextField(text: .constant(""), placeholder: "Email")
}
