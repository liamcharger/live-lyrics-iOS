//
//  NoInternetView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/11/23.
//

import SwiftUI

struct NoInternetView: View {
    @ObservedObject var networkManager = NetworkManager()
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 50).weight(.bold))
            VStack(spacing: 10) {
                Text("Oops!")
                    .font(.title.weight(.bold))
                Text("Your device is not connected to the internet. To continue, please connect to the internet.")
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical)
            Button(action: networkManager.checkStatus) {
                Text("Retry")
                    .font(.callout.weight(.semibold))
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            Spacer()
            Spacer()
        }
        .padding()
    }
}
