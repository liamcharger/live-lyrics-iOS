//
//  FeaturesView.swift
//  Lyrics
//
//  Created by Liam Willey on 11/3/23.
//

import SwiftUI

enum FeatureType {
    case outlined
    case filled
    case none
}

struct FeaturesView: View {
    @Binding var animState: AnimState
    
    @State private var selectedTab = 0
    
    var features: [FeaturesSection] = [
        FeaturesSection(title: "Brand New UI!", subtitle: "Experience a completely redesigned interface.", imageName: "sparkles", type: .none),
        FeaturesSection(title: "Folders", subtitle: "Organize your songs with folders.", imageName: "folder", type: .filled),
        FeaturesSection(title: "Recently Deleted", subtitle: "Never accidentally delete a song.", imageName: "trash", type: .outlined),
        FeaturesSection(title: "Notes", subtitle: "Add notes to your song to keep track of things you want to remember.", imageName: "doc.text", type: .none),
        FeaturesSection(title: "Keys", subtitle: "Add a key to your songs so you never forget them.", imageName: "music.note", type: .none),
        FeaturesSection(title: "And More", subtitle: "Play View, new customization options, and more.", imageName: "ellipsis.circle", type: .none)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("new_in_live_lyrics", comment: "What's New in Live Lyrics"))
                .frame(maxWidth: .infinity)
                .font(.largeTitle.bold())
            Spacer()
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    ForEach(0..<features.count, id: \.self) { index in
                        featureCard(features[index], type: features[index].type)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            }
            Spacer()
            Button {
                if selectedTab < features.count - 1 {
                    withAnimation {
                        selectedTab += 1
                    }
                } else {
                    withAnimation(Animation.bouncy(duration: 1.5)) {
                        animState = .fourth
                    }
                }
            } label: {
                if selectedTab < features.count - 1 {
                    Text(NSLocalizedString("next", comment: "Next"))
                        .modifier(NavButtonViewModifier())
                } else {
                    Text(NSLocalizedString("continue", comment: "Continue"))
                        .modifier(NavButtonViewModifier())
                }
            }
        }
    }
    
    func featureCard(_ feature: FeaturesSection, type: FeatureType) -> some View {
        VStack(spacing: 9) {
            Image(systemName: feature.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
            Spacer()
                .frame(height: 5)
            Text(feature.title)
                .font(.title)
                .fontWeight(.bold)
            Text(feature.subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct FeaturesSection: View {
    let title: String
    let subtitle: String
    let imageName: String
    let type: FeatureType
    
    var body: some View {
        if type == .outlined {
            VStack(alignment: .leading) {
                Image(systemName: imageName)
                    .font(.title.weight(.regular))
                    .padding([.top, .leading, .trailing], 10)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.bold))
                    Text(subtitle)
                        .font(.footnote)
                }
                .padding(12)
            }
            .padding(12)
            .foregroundColor(.blue)
            .cornerRadius(15)
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.blue, lineWidth: 3.5)
            }
            .frame(minHeight: 400)
        } else if type == .filled {
            VStack(alignment: .leading) {
                Image(systemName: imageName)
                    .font(.title.weight(.regular))
                    .padding([.top, .leading, .trailing], 10)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.bold))
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(Color(.white))
                }
                .padding(12)
            }
            .padding(12)
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(15)
            .frame(minHeight: 400)
        } else if type == .none {
            VStack(alignment: .leading) {
                Image(systemName: imageName)
                    .font(.title.weight(.regular))
                    .padding([.top, .leading, .trailing], 10)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.bold))
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                }
                .padding(12)
            }
            .padding(12)
            .foregroundColor(.primary)
            .background(Material.regular)
            .cornerRadius(15)
            .frame(minHeight: 400)
        }
    }
}

#Preview {
    FeaturesView(animState: .constant(.first))
}
