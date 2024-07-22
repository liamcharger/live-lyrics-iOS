//
//  Modifers.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

struct NavBarRowViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 23, height: 23)
            .padding(12)
            .font(.body.weight(.semibold))
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

struct NavBarButtonViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 23, height: 23)
            .padding(16)
            .font(.body.weight(.semibold))
            .background(Material.regular)
            .foregroundColor(.primary)
            .clipShape(Circle())
    }
}

struct NavButtonViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .font(.body.weight(.semibold))
            .background(.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}
