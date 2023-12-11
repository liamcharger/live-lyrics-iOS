//
//  ListHeaderView.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

struct ListHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .padding(12)
                .foregroundColor(.primary)
                .background(Material.regular)
                .clipShape(Capsule())
                .textCase(.uppercase)
                .font(.footnote.weight(.bold))
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

#Preview {
    ListHeaderView(title: "Songs")
}
