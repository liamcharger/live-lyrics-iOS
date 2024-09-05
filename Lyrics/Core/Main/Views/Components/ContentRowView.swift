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
    let color: Color
    
    init(_ title: String, icon: String, color: Color? = nil) {
        self.title = title
        self.icon = icon
        self.color = color ?? Color.primary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if icon == "apple_music" {
                    Image(icon)
                        .resizable()
                        .frame(width: 22, height: 22)
                } else {
                    FAText(iconName: icon, size: 20)
                        .foregroundColor(color)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundColor(.gray)
            }
            Text(title)
                .font(.system(size: 18).weight(.semibold))
                .frame(maxWidth: 95, alignment: .leading)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding()
        .background(Material.thin)
        .foregroundColor(.primary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ContentRowView("Recently Deleted", icon: "trash-can")
}
