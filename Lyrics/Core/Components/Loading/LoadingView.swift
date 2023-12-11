//
//  LoadingView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/9/23.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.trailing, 1)
            Text("Loading...")
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(12)
        .background(Material.regular)
        .clipShape(Capsule())
    }
}
