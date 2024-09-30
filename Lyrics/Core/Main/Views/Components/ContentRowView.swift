//
//  ContentRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/22/24.
//

import SwiftUI

struct ContentRowView: View {
    let title: String
    let icon: String
    let actionIcon: String
    let color: Color
    
    init(_ title: String, icon: String, color: Color? = nil, actionIcon: String? = nil) {
        self.title = title
        self.icon = icon
        self.color = color ?? Color.primary
        self.actionIcon = actionIcon ?? "chevron.right"
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 12) {
                if icon == "apple_music" {
                    Image(icon)
                        .resizable()
                        .frame(width: 22, height: 22)
                } else {
                    FAText(iconName: icon, size: 20)
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 18).weight(.semibold))
                    .frame(maxWidth: 102, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Image(systemName: actionIcon)
                .font(.body.weight(.medium))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .padding()
        .frame(maxHeight: .infinity)
        .frame(minHeight: 105)
        .background(Material.thin)
        .foregroundColor(.primary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ContentRowView("Recently Deleted", icon: "trash-can")
}
