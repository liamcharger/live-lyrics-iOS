//
//  FullscreenMessage.swift
//  Lyrics
//
//  Created by Liam Willey on 12/31/24.
//

import SwiftUI

struct FullscreenMessage: View {
    let imageName: String
    let title: String
    let spaceNavbar: Bool
    let isLoading: Bool
    
    func loadingText() -> Text {
        let selection = Int.random(in: 0...3) // We want to show just plain "Loading..." occasionally, so add an extra case
        
        switch selection {
        case 0:
            return Text("Working on it...")
        case 1:
            return Text("Doing cool things...")
        case 2:
            return Text("Queuing everything up...")
        default:
            return Text("Loading")
        }
    }
    
    init(imageName: String, title: String, spaceNavbar: Bool = false, isLoading: Bool = false) {
        self.imageName = imageName
        self.title = title
        self.spaceNavbar = spaceNavbar
        self.isLoading = isLoading
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Group {
                if isLoading {
                    if #available(iOS 18.0, *) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                            .symbolEffect(.rotate.wholeSymbol, options: .repeat(.periodic(delay: 0.5)), isActive: true)
                    } else {
                        Image(systemName: "clock")
                    }
                } else {
                    Image(systemName: imageName)
                }
            }
            .font(.system(size: 32).weight(.semibold))
            Group {
                if isLoading {
                    loadingText()
                } else {
                    Text(NSLocalizedString(title, comment: ""))
                }
            }
            .font(.title2.weight(.semibold))
            .multilineTextAlignment(.center)
            Spacer()
            if spaceNavbar {
                // 35 pts should center the content when there is a navbar
                Spacer()
                    .frame(height: 35)
            }
        }
        .padding()
        .foregroundColor(.gray)
    }
}
