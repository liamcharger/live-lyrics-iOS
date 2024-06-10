//
//  ToolsView.swift
//  Lyrics
//
//  Created by Liam Willey on 11/6/23.
//

import SwiftUI

struct ToolsView: View {
    var body: some View {
        VStack {
            ListHeaderView(title: "Tools")
            NavigationLink(destination: EmptyView()) {
                ListRowView(isEditing: .constant(false), title: "Live Queue", navArrow: "chevron.right")
            }
        }
    }
}

#Preview {
    ToolsView()
}
