//
//  ShowWhatsNew.swift
//  Lyrics
//
//  Created by Liam Willey on 11/3/23.
//

import SwiftUI

enum AnimState {
    case none
    case first
    case second
    case third
    case fourth
}

struct ShowWhatsNew: View {
    @State var animState: AnimState = .first
    
    @Binding var isDisplayed: Bool
    
    @State var isLoading = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ZStack {
                VStack {
                    Spacer()
                    Text(NSLocalizedString("hop_right_in", comment: "Let's hop back in."))
                        .font(.largeTitle.bold())
                    Spacer()
                    Button {
                        withAnimation(Animation.bouncy(duration: 1.5)) {
                            animState = .none
                        }
                        withAnimation {
                            isLoading = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(Animation.bouncy(duration: 1.5)) {
                                isDisplayed = false
                            }
                            NotificationManager().updateAppVersion()
                        }
                    } label: {
                        Text(NSLocalizedString("continue", comment: "Continue"))
                            .modifier(NavButtonViewModifier())
                    }
                }
                .scaleEffect(animState == .fourth ? 1.0 : 0.2)
                .blur(radius: animState == .fourth ? 0 : 20)
                .disabled(animState != .fourth)
                FeaturesView(animState: $animState)
                    .scaleEffect(animState == .third ? 1.0 : 0.2)
                    .blur(radius: animState == .third ? 0 : 20)
                Text(NSLocalizedString("welcome_to_lyrics", comment: "Welcome to Live Lyrics!"))
                    .font(.largeTitle.bold())
                    .scaleEffect(animState == .second ? 1.0 : 0.2)
                    .blur(radius: animState == .second ? 0 : 20)
                Text(NSLocalizedString("hello", comment: "Hello"))
                    .font(.largeTitle.bold())
                    .scaleEffect(animState == .first ? 1.0 : 0.2)
                    .blur(radius: animState == .first ? 0 : 20)
                if isLoading {
                    ProgressView()
                }
            }
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .padding(25)
        }
        .onAppear {
            withAnimation(Animation.bouncy(duration: 1.5).delay(1.0)) {
                animState = .first
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(Animation.bouncy(duration: 1.5)) {
                    animState = .second
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                withAnimation(Animation.bouncy(duration: 1.5)) {
                    animState = .third
                }
            }
        }
    }
}

#Preview {
    ShowWhatsNew(isDisplayed: .constant(true))
}
