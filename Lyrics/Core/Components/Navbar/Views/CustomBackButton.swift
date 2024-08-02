//
//  CustomBackButton.swift
//  Lyrics
//
//  Created by Liam Willey on 8/1/24.
//

import SwiftUI

struct CustomBackButton: View {
    @Environment(\.presentationMode) var presMode
    
    var body: some View {
        Button {
            presMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .padding()
                .font(.body.weight(.semibold))
                .background(Material.regular)
                .foregroundColor(.primary)
                .clipShape(Circle())
        }
    }
}

#Preview {
    CustomBackButton()
}
