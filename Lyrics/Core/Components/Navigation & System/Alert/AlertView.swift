//
//  AlertView.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

struct AlertView: View {
    let title: String
    let message: String
    let imageName: String
    let buttonText: String
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: imageName)
                .font(.system(size: 50).weight(.bold))
            VStack(spacing: 10) {
                Text(title)
                    .font(.title.weight(.bold))
                Text(message)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical)
            Button(action: {
                #if os(iOS)
                UIApplication.shared.open(URL(string: "https://apps.apple.com/us/app/lyrics-live/id6449195237")!, options: [:], completionHandler: nil)
                #endif
            }) {
                Text(buttonText)
                    .font(.callout)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AlertView(title: "Update Required", message: "Due to some changes with our database, Live Lyrics needs to be updated. We apologize for the inconvience.", imageName: "square.and.arrow.down", buttonText: "Update")
}
