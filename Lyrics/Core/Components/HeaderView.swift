//
//  HeaderView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/1/24.
//

import SwiftUI

struct HeaderView: View {
    let title: String
    let icon: String
    let color: Color
    var geo: GeometryProxy
    let counter: String
    
    init(_ title: String, icon: String, color: Color, geo: GeometryProxy, counter: String? = nil) {
        self.title = title
        self.icon = icon
        self.color = color
        self.geo = geo
        self.counter = counter ?? ""
    }
    
    var body: some View {
        ZStack {
            Group {
                Circle()
                    .foregroundColor(color)
                    .frame(width: geo.size.width / 4, height: geo.size.width / 4)
                    .offset(x: -100, y: -30)
                Circle()
                    .foregroundColor(color)
                    .frame(width: geo.size.width / 5, height: geo.size.width / 5)
                    .offset(x: 10, y: 15)
            }
            .offset(x: 65, y: 35)
            .blur(radius: 58)
            VStack(alignment: .leading, spacing: 14) {
                FAText(iconName: icon, size: 45)
                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                    if !counter.isEmpty {
                        Text(counter)
                            .font(.system(size: 12).weight(.bold))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 25)
            .padding(.horizontal, 10)
        }
    }
}
