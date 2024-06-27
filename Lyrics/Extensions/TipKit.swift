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
    var title: Text {
        Text("Introducing Play View")
    }
    
    var message: Text? {
        Text("Play View provides musicians with a distraction-free space during gigs, preventing accidental button presses and allowing them to stay fully engaged in their performance.")
    }
    
    var asset: Image? {
        Image(systemName: "play")
    }
    
    var options: [TipOption] {
        return [
            Tips.MaxDisplayCount(1)
        ]
    }
}

@available(iOS 17, *)
struct AutoscrollSpeedTip: Tip {
    var title: Text {
        Text("Looking to adjust scroll speed?")
    }
    
    var message: Text? {
        Text("To adjust the scroll speed, update the song's duration field in its edit view.")
    }
    
    var asset: Image? {
        Image(systemName: "hare")
    }
    
    var options: [TipOption] {
        return [
            Tips.MaxDisplayCount(1)
        ]
    }
}

@available(iOS 17, *)
struct VariationsTip: Tip {
    var title: Text {
        Text("Introducing Variations")
    }
    
    var message: Text? {
        Text("Keep versions of your song organized by creating variations for guitar chords, vocal parts, and more.")
    }
    
    var asset: Image? {
        Image(systemName: "rectangle.stack")
    }
    
    var options: [TipOption] {
        return [
            Tips.MaxDisplayCount(1)
        ]
    }
}

@available(iOS 17, *)
struct NotesViewTip: Tip {
    var title: Text {
        Text("Tip")
    }
    
    var message: Text? {
        Text("Notes are valuable guides, serving as reminders for crucial details in both practice sessions and performances.")
    }
    
    var options: [TipOption] {
        return [
            Tips.MaxDisplayCount(1)
        ]
    }
}
