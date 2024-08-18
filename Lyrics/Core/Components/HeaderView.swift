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
    let geo: GeometryProxy
    let counter: String
    
    let idiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    
    init(_ title: String, icon: String, color: Color, geo: GeometryProxy, counter: String? = nil) {
        self.title = title
        self.icon = icon
        self.color = color
        self.geo = geo
        self.counter = counter ?? ""
    }
    
    func width(for shape: Int) -> CGFloat {
        if shape == 0 {
            return idiom == .phone ? geo.size.width / 4 : geo.size.width / 6.5
        } else {
            return idiom == .phone ? geo.size.width / 5 : geo.size.width / 8
        }
    }
    
    var body: some View {
        ZStack {
            Group {
                Circle()
                    .foregroundColor(color)
                    .frame(width: width(for: 0), height: width(for: 0))
                    .offset(x: -100, y: -30)
                Circle()
                    .foregroundColor(color)
                    .frame(width: width(for: 1), height: width(for: 1))
                    .offset(x: 10, y: 15)
            }
            .offset(x: 65, y: 35)
            .blur(radius: idiom == .phone ? 58: 116)
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

#Preview {
    GeometryReader { geo in
        HeaderView("Recently Deleted", icon: "trash-can", color: .red, geo: geo)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
