//
//  ChooseAuthView.swift
//  Lyrics
//
//  Created by Liam Willey on 1/20/24.
//

import SwiftUI

struct ChooseAuthView: View {
    @AppStorage("showRegisterView") var showRegisterView = false
    
    func greetingLogic() -> String {
        let date = NSDate()
        let calendar = NSCalendar.current
        let currentHour = calendar.component(.hour, from: date as Date)
        let hourInt = Int(currentHour.description)!
        
        let newDay = 0
        let noon = 12
        let sunset = 18
        let midnight = 24
        
        var greetingText = "Hello."
        if hourInt >= newDay && hourInt <= noon {
            greetingText = NSLocalizedString("good_morning", comment: "Good Morning.")
        }
        else if hourInt > noon && hourInt <= sunset {
            greetingText = NSLocalizedString("good_afternoon", comment: "Good Afternoon.")
        }
        else if hourInt > sunset && hourInt <= midnight {
            greetingText = NSLocalizedString("good_evening", comment: "Good Evening.")
        }
        
        return greetingText
    }
    
    init() {
        showRegisterView = false
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Image("AuthBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                VStack {
                    Text(greetingLogic() + "\n" + NSLocalizedString("welcome_to_lyrics", comment: "Welcome to Live Lyrics."))
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    NavigationLink(isActive: $showRegisterView) {
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
                .frame(maxHeight: 400)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
                        .fill(Material.thin)
                )
                .clipped()
                .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 350 : UIScreen.main.bounds.width)
                .shadow(color: .black.opacity(0.8), radius: UIDevice.current.userInterfaceIdiom == .pad ? 50: 0)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ChooseAuthView()
}
