//
//  MoveRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/24/23.
//

import SwiftUI

struct RowView: View {
    let title: String
    let subtitle: String?
    let trackId: Int?
    let id: Int?
    let isExplicit: Int?
    @Binding var isLoading: Bool?
    
    var body: some View {
        if let subtitle = subtitle {
            if let trackId = trackId {
                HStack {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(title)
                                .multilineTextAlignment(.leading)
                                .font(.body.weight(.semibold))
                            if isExplicit == 1 {
                                Text("E")
                                    .font(.caption)
                                    .padding(4)
                                    .foregroundColor(.white)
                                    .background(Color.gray)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        Text(subtitle)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    if isLoading ?? false && id == trackId {
                        ProgressView()
                    }
                }
                .padding()
                .background(Material.regular)
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(title)
                            .multilineTextAlignment(.leading)
                            .font(.body.weight(.semibold))
                        Text(subtitle)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    if isLoading ?? false {
                        ProgressView()
                    }
                }
                .padding()
                .background(Material.regular)
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        } else {
            HStack {
                Text(title)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isLoading ?? false {
                    ProgressView()
                }
            }
            .padding()
            .background(Material.regular)
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    RowView(title: Folder.folder.title, subtitle: nil, trackId: nil, id: nil, isExplicit: 1, isLoading: .constant(false))
        .previewLayout(.sizeThatFits)
}
