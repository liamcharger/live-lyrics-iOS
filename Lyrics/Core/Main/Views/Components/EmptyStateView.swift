//
//  EmptyStateView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/20/24.
//

import SwiftUI

enum EmptyState {
    case songs
    case folders
}

struct EmptyStateView: View {
    let state: EmptyState
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            FAText(iconName: state == .songs ? "music-slash" : "folder-xmark", size: 26)
            Text(state == .songs ? NSLocalizedString("you_dont_have_any_songs", comment: "") : NSLocalizedString("you_dont_have_any_folders", comment: ""))
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .foregroundColor(.gray)
        .frame(minHeight: 160)
    }
}

#Preview {
    EmptyStateView(state: .songs)
}
