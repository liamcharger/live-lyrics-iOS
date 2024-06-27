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
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        CustomTextField(text: .constant(""), placeholder: "Email")
    }
}
