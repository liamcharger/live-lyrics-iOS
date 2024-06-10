//
//  ListIconButtonView.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

struct ListIconButtonView: View {
    let imageName: String
    let color: Color
    
    var body: some View {
        Image(systemName: imageName)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .clipShape(Circle())
    }
}

#Preview {
    ListIconButtonView(imageName: "trash", color: .red)
}
