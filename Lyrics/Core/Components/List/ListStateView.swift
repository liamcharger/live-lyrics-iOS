//
//  ListStateView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/15/24.
//

import SwiftUI

enum EmptyState {
    case songs
    case folders
    case folderSongs
    case demoAttachments
}

struct EmptyStateView: View {
    let state: EmptyState
    
    var icon: String {
        switch state {
        case .songs:
            return "music-slash"
        case .folders:
            return "folder-xmark"
        case .folderSongs:
            return "music-slash"
        case .demoAttachments:
            return "layer-group"
        }
    }
    var subtitle: String {
        switch state {
        case .songs:
            return NSLocalizedString("you_dont_have_any_songs", comment: "")
        case .folders:
            return NSLocalizedString("you_dont_have_any_folders", comment: "")
        case .folderSongs:
            return NSLocalizedString("you_dont_have_any_folder_songs", comment: "")
        case .demoAttachments:
            return NSLocalizedString("no_demo_attachments", comment: "")
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            FAText(iconName: icon, size: 35)
            Text(subtitle)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .foregroundColor(.gray)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 160)
    }
}
