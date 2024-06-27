//
//  ExploreView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/26/24.
//

import SwiftUI

struct ExploreView: View {
    @State var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavBar(title: NSLocalizedString("explore", comment: ""))
                .padding()
            Divider()
            GeometryReader { geo in
                ScrollView {
                    VStack {
                        ZStack {
                            Circle()
                                .frame(width: geo.size.width * 0.60, height: geo.size.width * 0.60)
                                .offset(x: -50, y: 2-0)
                            Circle()
                                .frame(width: geo.size.width * 0.27, height: geo.size.width * 0.27)
                                .offset(x: 70, y: 35)
                        }
                        .blur(radius: 40)
                        .foregroundColor(.blue.opacity(0.65))
                        .padding()
                        .frame(height: 360)
                        .overlay {
                            VStack(spacing: 20) {
                                VStack(spacing: 12) {
                                    Image(systemName: "rectangle.and.text.magnifyingglass")
                                        .font(.system(size: 55))
                                    Text("search_and_add")
                                        .font(.largeTitle.weight(.bold))
                                        .multilineTextAlignment(.center)
                                }
                                HStack(spacing: 5) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    TextField("search", text: $searchText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(Material.thin)
                                .clipShape(Capsule())
                                .shadow(color: .white.opacity(0.3), radius: 10)
                                .frame(width: geo.size.width * 0.70)
                            }
                        }
                        .padding(.vertical, 15)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("popular_songs")
                                .textCase(.uppercase)
                                .font(.system(size: 14).weight(.bold))
                            VStack {
                                ForEach(1...2, id: \.self) { _ in
                                    HStack {
                                        ForEach(geo.size.width < 393 ? 1...2 : 1...3, id: \.self) { index in
                                            VStack(alignment: .leading) {
                                                Text("E")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color(.lightGray))
                                                    .padding(3)
                                                    .background(Color.gray.opacity(0.3))
                                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                                Spacer()
                                                    .frame(minHeight: 30)
                                                Text("Example Song \(index)")
                                                    .font(.body.weight(.semibold))
                                            }
                                            .padding(13)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Material.regular)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ExploreView()
}
