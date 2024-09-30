//
//  TipKitResources.swift
//  Lyrics
//
//  Created by Liam Willey on 11/3/23.
//

import Foundation
import TipKit

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
struct JoinBandTip: Tip {
    var title: Text {
        Text("Want to add members to your band?")
    }
    
    var message: Text? {
        Text("Ask the band member to click the \"Join a Band\" button in previous view and enter the code you receive when clicking the button above.")
    }
    
    var image: Image? {
        Image(systemName: "person.2.badge.plus")
    }
}

@available(iOS 17, *)
struct LiveLyricsTipStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 10) {
                        configuration.image?
                            .font(.system(size: 26))
                        configuration.title?
                            .font(.title3.weight(.bold))
                    }
                    .padding(.trailing, 20)
                    configuration.message?
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: {
                    configuration.tip.invalidate(reason: .tipClosed)
                }, label: {
                    Image(systemName: "xmark")
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                })
                .frame(maxWidth: .infinity, alignment: .trailing)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
