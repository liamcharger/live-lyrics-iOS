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
        FeaturesSection(title: "Tags", subtitle: "A new way to organize your songs.", imageName: "sparkles"),
        FeaturesSection(title: "Autoscroll", subtitle: "Ensure smooth scrolling while you focus on performing.", imageName: "play"),
        FeaturesSection(title: "Metronome", subtitle: "Keep your rhythm steady with our built-in metronome.", imageName: "123.rectangle"),
        FeaturesSection(title: "Sharing", subtitle: "Effortlessly share songs with band members.", imageName: "square.and.arrow.up"),
        FeaturesSection(title: "And More", subtitle: "This update also includes several bug fixes and other improvements.", imageName: "ellipsis.circle")
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("new_in_live_lyrics", comment: "What's New in Live Lyrics"))
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

#Preview {
    FeaturesView(animState: .constant(.first))
}
