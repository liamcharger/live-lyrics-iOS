//
//  BandChooseRoleIcon.swift
//  Lyrics
//
//  Created by Liam Willey on 7/3/24.
//

import SwiftUI

struct BandChooseRoleIcon: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedIcon: String?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    let icons = ["music", "headphones", "volume-up", "random", "microphone", "microphone-alt", "record-vinyl", "guitar", "drum", "headphones-alt", "music-note", "radio", "sliders-h", "sliders-v", "waveform-path", "album-collection", "microphone-stand", "speakers"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Choose an Icon")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                Button(action: {dismiss()}) {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .background(Material.regular)
                        .clipShape(Circle())
                }
            }
            .padding()
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            VStack {
                                FAText(iconName: icon, size: 28)
                            }
                            .frame(width: 48, height: 48)
                            .background(Material.regular)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
    }
}
