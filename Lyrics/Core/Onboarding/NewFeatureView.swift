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
    
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            NewFeatureTitleView(title: feature.title, currentIndex: $currentIndex)
                .opacity(currentIndex == 0 ? 1 : 0)
            if currentIndex > feature.sections.count {
                // Force current index to one to only show a forward button
                NewFeatureSectionView(section: NewFeatureSection(id: feature.sections.count + 1, title: "Ready to try it out?", icon: "", subtitle: ""), currentIndex: .constant(1))
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
    }
}

struct NewFeatureTitleView: View {
    let title: String
    
    @Binding var currentIndex: Int
    
    @State private var subtitleOffset: CGFloat = 65
    @State private var titleOffset: CGFloat = 65
    
    @State private var titleOpacity: CGFloat = 0
    @State private var subtitleOpacity: CGFloat = 0
    
    @State private var titleBlur: CGFloat = 10
    @State private var subtitleBlur: CGFloat = 10
    
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

struct NewFeatureSectionView: View {
    let section: NewFeatureSection
    private let animation = Animation.bouncy(duration: 1.2)
    private var isLastSection: Bool {
        return section.icon.isEmpty && section.subtitle.isEmpty
    }
    
    @Binding var currentIndex: Int
    
    @State private var subtitleOffset: CGFloat = 65
    @State private var titleOffset: CGFloat = 65
    @State private var iconOffset: CGFloat = 65
    @State private var buttonOffset: CGFloat = 65
    
    @State private var titleOpacity: CGFloat = 0
    @State private var subtitleOpacity: CGFloat = 0
    @State private var iconOpacity: CGFloat = 0
    @State private var buttonOpacity: CGFloat = 0
    
    @State private var titleBlur: CGFloat = 10
    @State private var subtitleBlur: CGFloat = 10
    @State private var iconBlur: CGFloat = 10
    @State private var buttonBlur: CGFloat = 10
    
    @AppStorage("hasShownBandsIntro") var hasShownBandsIntro = false
    
    private func animateIcon(`in`: Bool) {
        withAnimation(animation) {
            iconOffset = `in` ? 0 : 65
            iconOpacity = `in` ? 0.9 : 0
            iconBlur = `in` ? 0 : 10
        }
    }
    private func animateTitle(`in`: Bool) {
        withAnimation(animation) {
            titleOffset = `in` ? 0 : 65
            titleOpacity = `in` ? 1 : 0
            titleBlur = `in` ? 0 : 10
        }
    }
    private func animateSubtitle(`in`: Bool) {
        withAnimation(animation) {
            subtitleOffset = `in` ? 0 : 65
            subtitleOpacity = `in` ? 0.7 : 0
            subtitleBlur = `in` ? 0 : 10
        }
    }
    private func animateButton(`in`: Bool) {
        withAnimation(animation) {
            buttonOffset = `in` ? 0 : 65
            buttonOpacity = `in` ? 1 : 0
            buttonBlur = `in` ? 0 : 10
        }
    }
    private func dismiss(completion: @escaping() -> Void) {
        if isLastSection {
            self.animateButton(in: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.animateTitle(in: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion()
                }
            }
        } else {
            self.animateButton(in: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.animateSubtitle(in: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.animateTitle(in: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.animateIcon(in: false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            completion()
                        }
                    }
                }
            }
        }
    }
    private func appear() {
        if isLastSection {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animateTitle(in: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.animateButton(in: true)
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animateSubtitle(in: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.animateTitle(in: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.animateIcon(in: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.animateButton(in: true)
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if !section.icon.isEmpty {
                FAText(iconName: section.icon, size: 50)
                    .offset(y: iconOffset)
                    .opacity(iconOpacity)
                    .blur(radius: iconBlur)
            }
            VStack(spacing: 10) {
                Text(NSLocalizedString(section.title, comment: ""))
                    .font(.system(size: 28).weight(.bold))
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
                    .opacity(titleOpacity)
                    .blur(radius: titleBlur)
                if !section.subtitle.isEmpty {
                    Text(NSLocalizedString(section.subtitle, comment: ""))
                        .offset(y: subtitleOffset)
                        .opacity(subtitleOpacity)
                        .blur(radius: subtitleBlur)
                }
            }
            HStack(spacing: 10) {
                if currentIndex > 1 {
                    Button {
                        dismiss {
                            self.currentIndex -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18).weight(.semibold))
                            .padding(18)
                            .background(Material.regular)
                            .foregroundColor(.primary)
                            .clipShape(Circle())
                    }
                }
                Button {
                    dismiss {
                        if isLastSection {
                            withAnimation(.easeInOut) {
                                self.hasShownBandsIntro = true
                            }
                        } else {
                            self.currentIndex += 1
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18).weight(.semibold))
                        .padding(18)
                        .background(Material.regular)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                }
            }
            .offset(y: buttonOffset)
            .opacity(buttonOpacity)
            .blur(radius: buttonBlur)
        }
        .multilineTextAlignment(.center)
        .padding(20)
        .onAppear(perform: appear)
    }
}

#Preview {
    NewFeatureView(feature: NewFeature(title: "Bands", sections: []))
}
