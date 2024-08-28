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
        FeaturesSection(title: "Collaboration", subtitle: "Work together on your songs and folders with fellow musicians in real-time.", imageName: "person.3"),
        FeaturesSection(title: "Song Variations", subtitle: "Keep versions of your song organized by creating variations for guitar chords, vocal parts, and more.", imageName: "square.stack.3d.down.right"),
        FeaturesSection(title: "Printing", subtitle: "Print your songs and their variations directly from the app for easy access in physical formats.", imageName: "printer"),
        FeaturesSection(title: "And More", subtitle: "This update also includes several bug fixes and other improvements.", imageName: "ellipsis.circle")
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
            LiveLyricsButton(selectedTab < features.count - 1 ? "Next" : "Continue") {
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
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct FeaturesSection {
    var title: String
    var subtitle: String
    var imageName: String
}

#Preview {
    FeaturesView(animState: .constant(.first))
}
