//
//  SongDataRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/28/23.
//

import SwiftUI

struct SongDataRowView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(subtitle)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    SongDataRowView(title: "Title", subtitle: "Subtitle")
}
