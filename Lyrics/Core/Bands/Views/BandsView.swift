//
//  BandsView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import SwiftUI

struct BandsView: View {
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    BandsView()
}
