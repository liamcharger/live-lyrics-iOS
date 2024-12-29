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
    let isSelected: Bool
    let showChevron: Bool
    let color: Color
    
    init(_ title: String, icon: String, color: Color? = nil, isSelected: Bool = false, showChevron: Bool = true) {
        self.title = title
        self.icon = icon
        self.color = color ?? Color.primary
        self.isSelected = isSelected
        self.showChevron = showChevron
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 12) {
                // So far, this check is sufficient because the only non-fa icon we'll be using is "apple_music"
                if icon == "apple_music" {
                    Image(icon)
                        .resizable()
                        .frame(width: 22, height: 22)
                } else {
                    FAText(iconName: icon, size: 20)
                        .foregroundColor(isSelected ? Color.blue : color)
                }
                Text(title)
                    .font(.system(size: 18).weight(.semibold))
                    .frame(maxWidth: 102, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Group {
                if isSelected {
                    Image(systemName: "checkmark")
                } else if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .padding()
        .frame(maxHeight: .infinity)
        .frame(minHeight: 105)
        .background(Material.regular)
        .foregroundStyle(isSelected ? Color.blue : Color.primary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue, lineWidth: 2)
            }
        }
    }
}

#Preview {
    ContentRowView("Recently Deleted", icon: "trash-can")
}
