//
//  CustomPasswordField.swift
//  Social Media
//
//  Created by Liam Willey on 2/17/23.
//

import SwiftUI

struct CustomPasswordField: View {
    @Binding var text: String
    let placeholder: String
    var body: some View {
        VStack(spacing: 18) {
            HStack {
                SecureField(placeholder, text: $text)
                    .padding(14)
                    .background(Material.regular)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    CustomPasswordField(text: .constant(""), placeholder: "Password")
}
