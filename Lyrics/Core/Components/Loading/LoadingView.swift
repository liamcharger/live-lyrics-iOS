//
//  LoadingView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/9/23.
//

import SwiftUI

struct LoadingView: View {
    let title: String? = nil
    
    var body: some View {
        HStack(spacing: 7) {
            ProgressView()
            Text(title ?? "Loading...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Material.regular)
        .clipShape(Capsule())
    }
}
