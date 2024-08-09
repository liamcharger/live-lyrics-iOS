//
//  CustomTextField.swift
//  Notes
//
//  Created by Liam Willey on 3/27/23.
//

import SwiftUI

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .padding(14)
                .background(Material.regular)
                .clipShape(Capsule())
        }
        .cornerRadius(10)
    }
}

#Preview {
    CustomTextField(text: .constant(""), placeholder: "Email")
}
