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
        Text("Play View keeps musicians focused by removing distractions during gigs.")
    }
    
    var image: Image? {
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
    
    var image: Image? {
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
    
    var image: Image? {
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
    
    var image: Image? {
        Image(systemName: "doc.text")
    }
    
    var options: [TipOption] {
        return [
            Tips.MaxDisplayCount(1)
        ]
    }
}

@available(iOS 17, *)
struct DatamuseRowViewTip: Tip {
    var title: Text {
        Text("Want to save a word?")
    }
    
    var message: Text? {
        Text("Click to copy to your clipboard.")
    }
    
    var image: Image? {
        Image(systemName: "doc.on.clipboard")
    }
    
    var options: [TipOption] {
        return [
            Tips.MaxDisplayCount(1)
        ]
    }
}

@available(iOS 17, *)
struct ExploreDetailViewTip: Tip {
    var title: Text {
        Text("Want to save this song?")
    }
    
    var message: Text? {
        Text("Click to add to your library.")
    }
    
    var image: Image? {
        Image(systemName: "doc.badge.plus")
    }
    
    var options: [TipOption] {
        return [
            Tips.MaxDisplayCount(1)
        ]
    }
}

@available(iOS 17, *)
struct DemoAttachmentTip: Tip {
    var title: Text {
        Text("Want to save this song?")
    }
    
    var message: Text? {
        Text("Click to add to your library.")
    }
    
    var image: Image? {
        Image(systemName: "doc.badge.plus")
    }
    
    var options: [TipOption] {
        return [
            Tips.MaxDisplayCount(1)
        ]
    }
}

@available(iOS 17, *)
struct LiveLyricsTipStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            HStack(alignment: .top, spacing: 12) {
                configuration.image?
                    .font(.system(size: 30))
                VStack(alignment: .leading, spacing: 7) {
                    configuration.title?
                        .font(.title3.weight(.bold))
                    configuration.message?
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: {
                    configuration.tip.invalidate(reason: .tipClosed)
                }, label: {
                    Image(systemName: "xmark")
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                })
            }
            ForEach(configuration.actions) { action in
                Button(action: action.handler, label: {
                    action.label()
                        .padding(12)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                })
            }
        }
        .padding()
    }
}
