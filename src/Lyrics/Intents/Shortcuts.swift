//
//  Shortcuts.swift
//  Lyrics
//
//  Created by Liam Willey on 1/18/24.
//

import Foundation
import AppIntents

@available(iOS 16, *)
struct MeditationShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartCreateNewSongIntent(),
            phrases: [
                "Create a new song",
                "Add a new song",
                "Create a new song with \(.applicationName)",
                "Add a new song with \(.applicationName)"
            ]
        )
        AppShortcut(
            intent: StartCreateNewFolderIntent(),
            phrases: [
                "Create a new folder",
                "Add a new folder",
                "Create a new folder with \(.applicationName)",
                "Add a new folder with \(.applicationName)"
            ]
        )
    }
}
