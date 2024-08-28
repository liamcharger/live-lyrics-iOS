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
            .padding()
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
            .frame(maxHeight: 50)
            .frame(maxWidth: .infinity)
            .font(.body.weight(.semibold))
            .background(.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

struct LiveLyricsButton: View {
    var action: () -> Void
    let title: String
    let showProgressIndicator: Bool
    
    @State var hasBeenPressed = false
    
    init(_ title: String, showProgressIndicator: Bool? = nil, action: @escaping () -> Void) {
        self.action = action
        self.title = title
        self.showProgressIndicator = showProgressIndicator ?? true
    }
    
    var body: some View {
        Button {
            hasBeenPressed = true
            action()
        } label: {
            if !hasBeenPressed {
                Text(NSLocalizedString(title, comment: ""))
                    .modifier(NavButtonViewModifier())
            } else {
                ProgressView()
                    .tint(.white)
                    .modifier(NavButtonViewModifier())
            }
        }
        .disabled(hasBeenPressed)
    }
}
