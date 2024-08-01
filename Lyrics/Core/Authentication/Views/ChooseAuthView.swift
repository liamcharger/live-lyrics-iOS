//
//  ChooseAuthView.swift
//  Lyrics
//
//  Created by Liam Willey on 1/20/24.
//

import SwiftUI

struct ChooseAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State var showLoginView = false
    @State var showRegisterView = false
    @State var areContentsHidden = true
    @State var scaleEffectDecor1: CGFloat = 7
    @State var scaleEffectDecor2: CGFloat = 4
    @State var scaleEffectActions: CGFloat = 3.5
    @State var scaleEffectLogo: CGFloat = 4.5
    @State var blurDecor1: CGFloat = 70
    @State var blurDecor2: CGFloat = 70
    @State var blurActions: CGFloat = 70
    @State var blurLogo: CGFloat = 70
    
    func dismissToAuth(login: Bool) {
        withAnimation(.bouncy(duration: 1.1)) {
            scaleEffectDecor1 = 7
            blurDecor1 = 70
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.bouncy(duration: 1.1)) {
                scaleEffectLogo = 3.5
                blurLogo = 70
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.bouncy(duration: 1.1)) {
                scaleEffectDecor2 = 4
                blurDecor2 = 70
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.bouncy(duration: 1.1)) {
                scaleEffectActions = 3.5
                blurActions = 70
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            withAnimation {
                areContentsHidden = true
                if login {
                    showLoginView = true
                } else {
                    showRegisterView = true
                }
            }
        }
    }
    func dismissToLogin() {
        dismissToAuth(login: true)
    }
    func dismissToRegister() {
        dismissToAuth(login: false)
    }
    func dismissFromAuth() {
        withAnimation {
            showLoginView = false
            showRegisterView = false
            areContentsHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.bouncy(duration: 1.1)) {
                scaleEffectLogo = 1
                blurLogo = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.bouncy(duration: 1.1)) {
                scaleEffectDecor1 = 1
                blurDecor1 = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.bouncy(duration: 1.1)) {
                scaleEffectDecor2 = 1
                blurDecor2 = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.bouncy(duration: 1.1)) {
                scaleEffectActions = 1
                blurActions = 0
            }
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ZStack {
                    ZStack {
                        Circle()
                            .foregroundColor(Color.blue)
                            .frame(width: geo.size.width / 3, height: geo.size.width / 3)
                            .offset(x: -40, y: -50)
                        Circle()
                            .foregroundColor(Color.blue)
                            .frame(width: geo.size.width / 4, height: geo.size.width / 4)
                            .offset(x: 70, y: 90)
                    }
                    .blur(radius: 58)
                    // Offset to center blur to compensate for bottom content
                    .offset(y: -30)
                    Group {
                        newFolder
                            .offset(x: geo.size.width / 2.6, y: -30)
                            .scaleEffect(scaleEffectDecor2)
                            .blur(radius: blurDecor2)
                        navbar
                            .scaleEffect(1.18)
                            .offset(x: -(geo.size.width / 4.5), y: 40)
                            .scaleEffect(scaleEffectDecor1)
                            .blur(radius: blurDecor2)
                        Image("Logo")
                            .resizable()
                            .frame(width: 110, height: 110)
                            .customShadow(color: .gray.opacity(0.7), radius: 30, x: -8, y: 2)
                            .scaleEffect(scaleEffectLogo)
                            .blur(radius: blurLogo)
                            .offset(y: -(geo.size.height / 4))
                    }
                    .opacity(areContentsHidden ? 0 : 1)
                    ZStack {
                        VisualEffectBlur(blurStyle: .systemMaterial)
                            .mask(LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.clear]),
                                startPoint: .bottom,
                                endPoint: .top
                            ))
                            .edgesIgnoringSafeArea(.all)
                            .frame(height: 450)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                        VStack {
                            Text("get_you_signed_in")
                                .font(.system(size: 28).weight(.bold))
                                .multilineTextAlignment(.center)
                            VStack(spacing: 12) {
                                Button {
                                    dismissToLogin()
                                } label: {
                                    Text("Sign In")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .font(.body.weight(.semibold))
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                                Button {
                                    dismissToRegister()
                                } label: {
                                    Text("No account? ") + Text("Sign Up").bold()
                                }
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .scaleEffect(scaleEffectActions)
                        .blur(radius: blurActions)
                        .opacity(areContentsHidden ? 0 : 1)
                        .padding()
                    }
                    if showLoginView {
                        LoginView(action: {dismissFromAuth()})
                    } else if showRegisterView {
                        RegistrationView(action: {dismissFromAuth()})
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Opening animation
            dismissFromAuth()
        }
    }
    
    var navbar: some View {
        HStack {
            Image(systemName: "play")
                .padding()
                .font(.body.weight(.semibold))
                .foregroundColor(.blue)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.blue, lineWidth: 2.5)
                }
            FAText(iconName: "book", size: 18)
                .frame(width: 23, height: 23)
                .padding(16)
                .font(.body.weight(.semibold))
                .background(Color(.darkGray))
                .foregroundColor(.primary)
                .clipShape(Circle())
            Image(systemName: "textformat.size")
                .frame(width: 23, height: 23)
                .padding(16)
                .font(.body.weight(.semibold))
                .background(Color(.darkGray))
                .foregroundColor(.primary)
                .clipShape(Circle())
            FAText(iconName: "ellipsis", size: 18)
                .frame(width: 23, height: 23)
                .padding(16)
                .font(.body.weight(.semibold))
                .background(Color(.darkGray))
                .foregroundColor(.primary)
                .clipShape(Circle())
        }
        .padding(12)
        .background(Material.thin)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Material.ultraThin, lineWidth: 1)
        }
    }
    
    var newFolder: some View {
        HStack(spacing: 7) {
            FAText(iconName: "folder-plus", size: 18)
            Text("New Folder")
        }
        .padding()
        .foregroundColor(.white)
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .customShadow(color: .white.opacity(0.7), radius: 20, x: -10, y: 8)
    }
}

#Preview {
    ChooseAuthView()
        .environmentObject(AuthViewModel())
}
