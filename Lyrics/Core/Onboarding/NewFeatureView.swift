//
//  NewFeatureView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/24/24.
//

import SwiftUI
import FluidGradient

struct NewFeature {
    var title: String
    var sections: [NewFeatureSection]
}

struct NewFeatureSection: Identifiable {
    var id: Int
    var title: String
    var icon: String
    var subtitle: String
}

struct NewFeatureView: View {
    let feature: NewFeature
    
    @State var subtitleOffset: CGFloat = 65
    @State var titleOffset: CGFloat = 65
    
    @State var titleOpacity: CGFloat = 0
    @State var subtitleOpacity: CGFloat = 0
    
    @State var titleBlur: CGFloat = 10
    @State var subtitleBlur: CGFloat = 10
    
    @State var currentIndex = 0
    
    let animation = Animation.bouncy(duration: 1.2)
    
    func animateTitle(`in`: Bool) {
        withAnimation(animation) {
            titleOffset = `in` ? 0 : 65
            titleOpacity = `in` ? 1 : 0
            titleBlur = `in` ? 0 : 10
        }
    }
    func animateSubtitle(`in`: Bool) {
        withAnimation(animation) {
            subtitleOffset = `in` ? 0 : 65
            subtitleOpacity = `in` ? 0.7 : 0
            subtitleBlur = `in` ? 0 : 10
        }
    }
    
    var body: some View {
        ZStack {
            NewFeatureTitleView(title: feature.title,
                                subtitleOffset: $subtitleOffset,
                                titleOffset: $titleOffset,
                                titleOpacity: $titleOpacity,
                                subtitleOpacity: $subtitleOpacity,
                                titleBlur: $titleBlur,
                                subtitleBlur: $subtitleBlur)
            .opacity(currentIndex == 0 ? 1 : 0)
            if currentIndex > feature.sections.count {
                Text("Continue")
            } else {
                ForEach(feature.sections) { section in
                    if currentIndex == section.id {
                        NewFeatureSectionView(section: section, currentIndex: $currentIndex)
                    }
                }
            }
            FluidGradient(blobs: [.blue, .blue.opacity(0.7)],
                          highlights: [.purple.opacity(0.6)],
                          speed: 0.3,
                          blur: 0.75)
            .zIndex(-999)
            .ignoresSafeArea()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animateSubtitle(in: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.animateTitle(in: true)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.animateTitle(in: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.animateSubtitle(in: false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.currentIndex = 1
                        }
                    }
                }
            }
        }
    }
}

struct NewFeatureTitleView: View {
    let title: String
    
    @Binding var subtitleOffset: CGFloat
    @Binding var titleOffset: CGFloat
    
    @Binding var titleOpacity: CGFloat
    @Binding var subtitleOpacity: CGFloat
    
    @Binding var titleBlur: CGFloat
    @Binding var subtitleBlur: CGFloat
    
    var body: some View {
        VStack(spacing: 3) {
            Text("Introducing")
                .opacity(0.75)
                .font(.system(size: 26).weight(.semibold))
                .offset(y: subtitleOffset)
                .opacity(subtitleOpacity)
                .blur(radius: subtitleBlur)
            Text(NSLocalizedString(title, comment: ""))
                .font(.system(size: 38).weight(.bold))
                .offset(y: titleOffset)
                .opacity(titleOpacity)
                .opacity(titleOpacity)
                .blur(radius: titleBlur)
        }
        .padding()
    }
}

struct NewFeatureSectionView: View {
    let section: NewFeatureSection
    let animation = Animation.bouncy(duration: 1.2)
    
    @Binding var currentIndex: Int
    
    @State var subtitleOffset: CGFloat = 65
    @State var titleOffset: CGFloat = 65
    @State var iconOffset: CGFloat = 65
    
    @State var titleOpacity: CGFloat = 0
    @State var subtitleOpacity: CGFloat = 0
    @State var iconOpacity: CGFloat = 0
    
    @State var titleBlur: CGFloat = 10
    @State var subtitleBlur: CGFloat = 10
    @State var iconBlur: CGFloat = 10
    
    func animateIcon(`in`: Bool) {
        withAnimation(animation) {
            iconOffset = `in` ? 0 : 65
            iconOpacity = `in` ? 1 : 0
            iconBlur = `in` ? 0 : 10
        }
    }
    func animateTitle(`in`: Bool) {
        withAnimation(animation) {
            titleOffset = `in` ? 0 : 65
            titleOpacity = `in` ? 1 : 0
            titleBlur = `in` ? 0 : 10
        }
    }
    func animateSubtitle(`in`: Bool) {
        withAnimation(animation) {
            subtitleOffset = `in` ? 0 : 65
            subtitleOpacity = `in` ? 0.7 : 0
            subtitleBlur = `in` ? 0 : 10
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            FAText(iconName: section.icon, size: 50)
                .opacity(0.9)
                .offset(y: iconOffset)
                .opacity(iconOpacity)
                .blur(radius: iconBlur)
            Text(NSLocalizedString(section.title, comment: ""))
                .font(.system(size: 28).weight(.bold))
                .offset(y: titleOffset)
                .opacity(titleOpacity)
                .opacity(titleOpacity)
                .blur(radius: titleBlur)
            Text(NSLocalizedString(section.subtitle, comment: ""))
                .opacity(0.75)
                .offset(y: subtitleOffset)
                .opacity(subtitleOpacity)
                .blur(radius: subtitleBlur)
        }
        .multilineTextAlignment(.center)
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animateSubtitle(in: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.animateTitle(in: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.animateIcon(in: true)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    self.animateIcon(in: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.animateTitle(in: false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.animateSubtitle(in: false)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.currentIndex += 1
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NewFeatureView(feature: NewFeature(title: "Bands", sections: []))
}
