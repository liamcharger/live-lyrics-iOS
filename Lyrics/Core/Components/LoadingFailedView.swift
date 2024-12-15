//
//  LoadingFailedView.swift
//  Lyrics
//
//  Created by Liam Willey on 12/14/24.
//

import SwiftUI

struct LoadingFailedView: View {
    @Environment(\.presentationMode) var presMode
    
    var body: some View {
        VStack {
            VStack(spacing: 18) {
                FAText(iconName: "warning", size: 60)
                    .foregroundStyle(.yellow)
                Text("Hmm...we had a problem loading what you requested.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.largeTitle.weight(.bold))
                Text("Try again in a few minutes, and make sure you're online.")
                    .font(.system(size: 20))
            }
            .multilineTextAlignment(.center)
            .frame(maxHeight: .infinity, alignment: .center)
            Spacer()
            VStack(spacing: 12) {
                LiveLyricsButton("Understood", showProgressIndicator: .constant(false)) {
                    presMode.wrappedValue.dismiss()
                }
            }
        }
        .padding()
    }
}

#Preview {
    LoadingFailedView()
}
