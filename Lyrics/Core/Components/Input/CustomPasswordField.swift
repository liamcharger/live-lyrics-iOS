//
//  CustomPasswordField.swift
//  Social Media
//
//  Created by Liam Willey on 2/17/23.
//

import SwiftUI

struct CustomPasswordField: View {
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
        VStack(spacing: 18) {
            HStack(spacing: 7) {
                if let image {
                    Image(systemName: image)
                        .foregroundStyle(.gray)
                        .frame(minWidth: 25)
                }
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
            }
            .padding(14)
            .background(Material.regular)
            .clipShape(Capsule())
            .onTapGesture {
                isFocused = true // Focuses the keyboard even if the material around the TextField is pressed
            }
        }
    }
}

#Preview {
    CustomPasswordField(text: .constant(""), placeholder: "Password")
}
