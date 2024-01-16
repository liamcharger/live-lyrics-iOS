//
//  TipKitResources.swift
//  Lyrics
//
//  Created by Liam Willey on 11/3/23.
//

import Foundation
import TipKit

@available(iOS 17, *)
struct PlayViewTip: Tip {
    @Parameter
    static var showTip: Bool = true
    static var numberOfTimesVisited: Event = Event (id: "com.chargertech.Lyrics.numberOfTimesPlayViewTipVisited")
    
    var title: Text {
        Text("Introducing Play View")
    }
    
    var message: Text? {
        Text("Play View introduces a new, distraction free way to experience live performances, designed for performers, by performers.")
    }
    
    var asset: Image? {
        Image(systemName: "play")
    }
    
    var options: [TipOption] {
        return [
            Tips.MaxDisplayCount(1)
        ]
    }
    
    var rules: [Rule] {
        return [
            #Rule(Self.numberOfTimesVisited) { $0.donations.count > 0}
        ]
    }
}

@available(iOS 17, *)
struct NotesViewTip: Tip {
    @Parameter
    static var showTip: Bool = true
    static var numberOfTimesVisited: Event = Event(id: "com.chargertech.Lyrics.numberOfTimesNotesViewTipVisited")
    
    var title: Text {
        Text("Tip")
    }
    
    var message: Text? {
        Text(NSLocalizedString("notes_tip", comment: "Notes are valuable guides, serving as reminders for crucial details in both practice sessions and performances."))
    }
    
    var options: [TipOption] {
        return [
            Tips.MaxDisplayCount(1)
        ]
    }
}
