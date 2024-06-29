//
//  CustomBackButton.swift
//  Lyrics
//
//  Created by Liam Willey on 6/29/24.
//

import SwiftUI

struct CustomBackButton: View {
    @Environment(\.presentationMode) var presMode
    
    @Binding var dismiss: Bool
    
    init(dismiss: Binding<Bool> = .constant(false)) {
        self._dismiss = dismiss
    }
    
    var body: some View {
        Button {
            if dismiss {
                dismiss = false
            } else {
                presMode.wrappedValue.dismiss()
            }
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
