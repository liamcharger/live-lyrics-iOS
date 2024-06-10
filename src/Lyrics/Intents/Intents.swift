//
//  Intents.swift
//  Lyrics
//
//  Created by Liam Willey on 1/18/24.
//

import AppIntents
import SwiftUI

@available(iOS 16, *)
struct StartCreateNewSongIntent: AppIntent {
    @AppStorage(showNewSongKey) static var showNewSong = false
    
    static let title: LocalizedStringResource = "Create a New Song"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        StartCreateNewSongIntent.showNewSong = true
        return .result(dialog: "Okay, creating a new song.")
    }
}

@available(iOS 16, *)
struct StartCreateNewFolderIntent: AppIntent {
    @AppStorage(showNewFolderKey) static var showNewFolder = false
    
    static let title: LocalizedStringResource = "Create a New Folder"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        StartCreateNewFolderIntent.showNewFolder = true
        return .result(dialog: "Okay, creating a new folder.")
    }
}
