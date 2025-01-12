//
//  TipKitResources.swift
//  Lyrics
//
//  Created by Liam Willey on 11/3/23.
//

import Foundation
import TipKit

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
struct ShareByRoleTip: Tip {
    var title: Text {
        Text("Looking to share the song by band member roles?")
    }
    
    var message: Text? {
        Text("Join a band if you haven't already, select it below, then tap this menu to select \"Role\".")
    }
    
    var image: Image? {
        Image(systemName: "square.and.arrow.up")
    }
}

@available(iOS 17, *)
struct LiveLyricsTipStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .center, spacing: 10) {
                    configuration.image
                        .font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        configuration.title?
                            .fontWeight(.bold)
                        configuration.message?
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: {
                    configuration.tip.invalidate(reason: .tipClosed)
                }, label: {
                    Image(systemName: "xmark")
                        .fontWeight(.medium)
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

#Preview {
    if #available(iOS 17.0, *) {
        VStack {
            Text("Testing piece of multiline text. Here for a UI test.")
                .font(.largeTitle.weight(.bold))
                .padding()
            Color.blue.frame(height: 70)
            Text("Another piece of multiline text. Here for a UI test.")
                .padding()
                .popoverTip(ExploreDetailViewTip(), arrowEdge: .bottom)
                .tipViewStyle(LiveLyricsTipStyle())
        }
        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity)
        .task {
            do {
                try Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
                try Tips.resetDatastore()
            } catch {
                print(error)
            }
        }
    } else {
        EmptyView()
    }
}
