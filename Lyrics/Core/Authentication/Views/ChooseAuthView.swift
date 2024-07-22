//
//  ChooseAuthView.swift
//  Lyrics
//
//  Created by Liam Willey on 1/20/24.
//

import SwiftUI

struct ChooseAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    VStack {
                        Text(greeting())
                        Text(NSLocalizedString("welcome_to", comment: ""))
                        Text(NSLocalizedString("live_lyrics", comment: ""))
                    }
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    Wave(strength: 5, frequency: 50)
                        .stroke(Color.primary, lineWidth: 4.5)
                        .padding(.horizontal, -18)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.clear)
                    VStack {
                        NavigationLink {
                            RegistrationView()
                        } label: {
                            Text("Sign Up")
                                .modifier(NavButtonViewModifier())
                        }
                        NavigationLink {
                            LoginView()
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
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ChooseAuthView()
        .environmentObject(AuthViewModel())
}
