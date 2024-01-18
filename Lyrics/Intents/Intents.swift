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
    @AppStorage(showNewSongKey) var showNewSong = false
    
    static let title: LocalizedStringResource = "Create a New Song"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        showNewSong = true
        return .result(dialog: "Okay, creating a new song.")
    }
}

@available(iOS 16, *)
struct StartCreateNewFolderIntent: AppIntent {
    @AppStorage(showNewFolderKey) var showNewFolder = false
    
    static let title: LocalizedStringResource = "Create a New Folder"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        showNewFolder = true
        return .result(dialog: "Okay, creating a new folder.")
    }
}
