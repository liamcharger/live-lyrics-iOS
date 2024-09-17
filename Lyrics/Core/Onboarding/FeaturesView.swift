//
//  FeaturesView.swift
//  Lyrics
//
//  Created by Liam Willey on 11/3/23.
//

import SwiftUI

struct FeaturesView: View {
    @Binding var animState: AnimState
    
    @State private var selectedTab = 0
    
    var features: [FeaturesSection] = [
        FeaturesSection(title: "Bands", subtitle: "Add a description here...", imageName: "guitar", pro: false),
        FeaturesSection(title: "Song Catalog", subtitle: "access_to_worlds_largest_lyric_database", imageName: "music-magnifying-glass", pro: false),
        FeaturesSection(title: "Demo Attachments", subtitle: "access_to_demo_attachments", imageName: "file-audio", pro: true),
        FeaturesSection(title: "Word Assistant", subtitle: "world_of_worlds_at_your_fingertips", imageName: "hand-pointer", pro: true),
        FeaturesSection(title: "Tuner", subtitle: "access_to_tuner", imageName: "sliders", pro: true),
        FeaturesSection(title: "And More", subtitle: "This update also includes several bug fixes and other improvements.", imageName: "circle-ellipsis", pro: false)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("What's New in Live Lyrics")
                .frame(maxWidth: .infinity)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    ForEach(0..<features.count, id: \.self) { index in
                        featureCard(features[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            }
            Spacer()
            LiveLyricsButton(selectedTab < features.count - 1 ? "Next" : "Continue", showProgressIndicator: .constant(false)) {
                if selectedTab < features.count - 1 {
                    withAnimation {
                        selectedTab += 1
                    }
                } else {
                    withAnimation(Animation.bouncy(duration: 1.5)) {
                        animState = .fourth
                    }
                }
            }
        }
    }
    
    func featureCard(_ feature: FeaturesSection) -> some View {
        VStack(spacing: 9) {
            ZStack(alignment: .topLeading) {
                FAText(iconName: feature.imageName, size: 90, style: .regular)
            }
            Spacer()
                .frame(height: 5)
            HStack(alignment: .center) {
                Text(NSLocalizedString(feature.title, comment: ""))
                    .font(.title)
                    .fontWeight(.bold)
                if feature.pro {
                    Text("Pro")
                        .font(.system(size: 12).weight(.medium))
                        .padding(5)
                        .padding(.horizontal, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            Text(NSLocalizedString(feature.subtitle, comment: ""))
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct FeaturesSection {
    var title: String
    var subtitle: String
    var imageName: String
    var pro: Bool
}

#Preview {
    FeaturesView(animState: .constant(.first))
}
