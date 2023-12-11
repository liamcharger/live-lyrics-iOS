//
//  NewPlayViewView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/7/23.
//

import SwiftUI

struct NewPlayViewView: View {
    @Environment(\.presentationMode) var presMode
    var body: some View {
        VStack {
            Image(systemName: "play")
                .font(.system(size: 40).weight(.bold))
                .padding(.top)
            Text("Welcome to Play View.")
                .padding()
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            Spacer()
            Text(NSLocalizedString("play_view_description", comment: "Play View provides musicians with a distraction-free space during gigs, preventing accidental button presses and allowing them to stay fully engaged in their performance."))
                .multilineTextAlignment(.center)
            Spacer()
            Button(action: {presMode.wrappedValue.dismiss()}, label: {
                Text(NSLocalizedString("continue", comment: "Continue"))
                    .modifier(NavButtonViewModifier())
            })
        }
        .padding()
    }
}

#Preview {
    NewPlayViewView()
}
