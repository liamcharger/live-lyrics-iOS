//
//  ChooseAuthView.swift
//  Lyrics
//
//  Created by Liam Willey on 1/20/24.
//

import SwiftUI

struct ChooseAuthView: View {
    @AppStorage("authViewState") var authViewState = "choose"
    
    @State private var blurLoginView = true
    @State private var blurRegisterView = true
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    func greetingLogic() -> String {
        let date = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        
        var greetingText = "Hello."
        switch currentHour {
        case 0..<12:
            greetingText = NSLocalizedString("good_morning", comment: "Good Morning.")
        case 12..<18:
            greetingText = NSLocalizedString("good_afternoon", comment: "Good Afternoon.")
        default:
            greetingText = NSLocalizedString("good_evening", comment: "Good Evening.")
        }
        return greetingText
    }
    
    init() {
        authViewState = "choose"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    VStack {
                        Text(greetingLogic())
                        Text(NSLocalizedString("welcome_to", comment: "Welcome to"))
                        Text(NSLocalizedString("live_lyrics", comment: "Live Lyrics."))
                    }
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    Wave(strength: 5, frequency: 50)
                        .stroke(Color.primary, lineWidth: 4.5)
                        .padding(.horizontal, -18)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.clear)
                    VStack {
                        Button {
                            withAnimation {
                                blurLoginView = true
                                blurRegisterView = false
                                authViewState = "register"
                            }
                        } label: {
                            Text("Sign Up")
                                .modifier(NavButtonViewModifier())
                        }
                        Button {
                            withAnimation {
                                blurLoginView = true
                                blurRegisterView = false
                                authViewState = "login"
                            }
                        } label: {
                            Text("Sign In")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .font(.body.weight(.semibold))
                                .background(Material.regular)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding()
                .frame(maxHeight: 350)
                .blur(radius: (blurLoginView && blurRegisterView) ? 0 : 5)
                .opacity((blurLoginView && blurRegisterView) ? 1 : 0)
                .disabled(!(blurLoginView && blurRegisterView))
                .zIndex((blurLoginView && blurRegisterView) ? 1 : 0)
                VStack {
                    LoginView()
                        .environmentObject(authViewModel)
                }
                .blur(radius: blurLoginView ? 5 : 0)
                .opacity(blurLoginView ? 0 : 1)
                .disabled(blurLoginView)
                .zIndex(blurLoginView ? 1 : 0)
                VStack {
                    RegistrationView()
                        .environmentObject(authViewModel)
                }
                .blur(radius: blurRegisterView ? 5 : 0)
                .opacity(blurRegisterView ? 0 : 1)
                .disabled(blurRegisterView)
                .zIndex(blurRegisterView ? 1 : 0)
            }
            .onChange(of: authViewState) { newValue in
                if newValue == "login" {
                    withAnimation {
                        blurLoginView = false
                        blurRegisterView = true
                    }
                } else if newValue == "register" {
                    withAnimation {
                        blurLoginView = true
                        blurRegisterView = false
                    }
                } else {
                    withAnimation {
                        blurLoginView = true
                        blurRegisterView = true
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

#Preview {
    ChooseAuthView()
        .environmentObject(AuthViewModel())
}
