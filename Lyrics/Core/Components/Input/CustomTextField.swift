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
        TextField(NSLocalizedString(placeholder, comment: ""), text: $text)
            .padding(14)
            .background(Material.regular)
            .clipShape(Capsule())
    }
}

#Preview {
    CustomTextField(text: .constant(""), placeholder: "Email")
}
