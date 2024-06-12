//
//  SettingsView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.presentationMode) var presMode
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var user: User
    
    @State var errorMessage = ""
    
    @State var showError = false
    @State var showInfo = false
    @State var showSettings = false
    @State var toggle: Bool
    @State var enableAutoscroll: Bool
    @State var isExplicit: Bool
    @State var selection: String?
    @State var wordCountStyle: String?
    @State var metronomeStyle: [String] = []
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    func fetchUser(withUid uid: String) {
        settingsViewModel.fetchUser(withUid: uid)
    }
    
    init(user: User) {
        self.user = user
        self.settingsViewModel = SettingsViewModel(user: user)
        
        _toggle = State(initialValue: user.wordCount ?? true)
        _enableAutoscroll = State(initialValue: user.enableAutoscroll ?? true)
        _isExplicit = State(initialValue: user.showsExplicitSongs ?? true)
        _selection = State(initialValue: user.showDataUnderSong ?? "None")
        _wordCountStyle = State(initialValue: user.wordCountStyle ?? "Words")
        _metronomeStyle = State(initialValue: user.metronomeStyle ?? ["Audio", "Vibrations"])
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Settings")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                Button(action: {presMode.wrappedValue.dismiss()}) {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .background(Material.regular)
                        .clipShape(Circle())
                }
            }
            .padding()
            Divider()
            ScrollView {
                //                if !NetworkManager.shared.getNetworkState() {
                //                    VStack(spacing: 0) {
                //                        Group {
                //                            Text("You're offline. Please connect to the internet to update settings. ") + Text("Open Settings?").foregroundColor(.blue)
                //                        }
                //                        .padding()
                //                        .foregroundColor(.gray)
                //                        .frame(maxWidth: .infinity, alignment: .center)
                //                        .onTapGesture {
                // Open Settings app without the deeplink to app settings
                //                            guard let settingsURL = URL(string: "") else { return }
                //                            if UIApplication.shared.canOpenURL(settingsURL) {
                //                                UIApplication.shared.open(settingsURL)
                //                            }
                //                        }
                //                        Divider()
                //                    }
                //                }
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 7) {
                                Text("Enable\nWord Count")
                                Spacer()
                                Toggle(isOn: $toggle, label: {})
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Material.regular)
                    .cornerRadius(20)
                    .foregroundColor(.primary)
                    HStack(spacing: 7) {
                        Text("Word Count Style")
                        Spacer()
                        Menu {
                            Button(action: {wordCountStyle = "Characters"}) {
                                Label("Characters", systemImage: wordCountStyle == "Characters" ? "checkmark" : "")
                            }
                            Button(action: {wordCountStyle = "Words"}) {
                                Label("Words", systemImage: wordCountStyle == "Words" ? "checkmark" : "")
                            }
                            Button(action: {wordCountStyle = "Spaces"}) {
                                Label("Spaces", systemImage: wordCountStyle == "Spaces" ? "checkmark" : "")
                            }
                            Button(action: {wordCountStyle = "Paragraphs"}) {
                                Label("Paragraphs", systemImage: wordCountStyle == "Paragraphs" ? "checkmark" : "")
                            }
                        } label: {
                            Text(wordCountStyle ?? "Choose an Option")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Material.regular)
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                    .opacity(toggle ? 1 : 0.5)
                    .disabled(!toggle)
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 7) {
                                Text("Song Subtitle")
                                Spacer()
                                Menu {
                                    Button(action: {selection = "Show Date"}) {
                                        Label("Date", systemImage: selection == "Show Date" ? "checkmark" : "")
                                    }
                                    Button(action: {selection = "Show Lyrics"}) {
                                        Label("Lyrics", systemImage: selection == "Show Lyrics" ? "checkmark" : "")
                                    }
                                    Button(action: {selection = "Show Artist"}) {
                                        Label("Artist", systemImage: selection == "Show Artist" ? "checkmark" : "")
                                    }
                                    Button(action: {selection = "None"}) {
                                        Label("None", systemImage: selection == "None" ? "checkmark" : "")
                                    }
                                } label: {
                                    HStack {
                                        Text(selection ?? "Choose an Option")
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background {
                        Rectangle()
                            .fill(.clear)
                            .background(Material.regular)
                            .mask { Capsule() }
                    }
                    .foregroundColor(.primary)
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 7) {
                                Text("Enable Autoscroll")
                                Spacer()
                                Toggle(isOn: $enableAutoscroll, label: {})
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Material.regular)
                    .cornerRadius(20)
                    .foregroundColor(.primary)
                    HStack(spacing: 7) {
                        Text("Metronome Style")
                        Spacer()
                        Menu {
                            Button(action: {
                                let index = metronomeStyle.firstIndex(of: "Audio")
                                
                                if let index = index {
                                    metronomeStyle.remove(at: index)
                                } else {
                                    metronomeStyle.append("Audio")
                                }
                            }) {
                                Label("Audio", systemImage: metronomeStyle.contains("Audio") ? "checkmark" : "")
                            }
                            Button(action: {
                                let index = metronomeStyle.firstIndex(of: "Vibrations")
                                
                                if let index = index {
                                    metronomeStyle.remove(at: index)
                                } else {
                                    metronomeStyle.append("Vibrations")
                                }
                            }) {
                                Label("Vibrations", systemImage: metronomeStyle.contains("Vibrations") ? "checkmark" : "")
                            }
                        } label: {
                            Text({
                                if metronomeStyle.count > 1 {
                                    return "\(metronomeStyle.first ?? ""), \(metronomeStyle.last ?? "")"
                                } else if metronomeStyle.count == 1 {
                                    return metronomeStyle.first ?? ""
                                } else {
                                    return "None"
                                }
                            }())
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Material.regular)
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                    Button {
                        Task {
                            try? await AppStore.sync()
                            presMode.wrappedValue.dismiss()
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 7) {
                                    Text("Restore In-App Purchases")
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background {
                            Rectangle()
                                .fill(.clear)
                                .background(Material.regular)
                                .mask { Capsule() }
                        }
                        .foregroundColor(.primary)
                    }
                    .padding(.top, 10)
                }
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .padding(.top)
                .padding(.horizontal)
            }
            Divider()
            Button {
                settingsViewModel.updateSettings(user, wordCount: toggle, data: selection ?? "None", wordCountStyle: wordCountStyle ?? "Words", enableAutoscroll: enableAutoscroll, showsExplicitSongs: isExplicit, metronomeStyle: metronomeStyle) { success, errorMessage in
                    if success {
                        presMode.wrappedValue.dismiss()
                    } else {
                        self.showError = true
                        self.errorMessage = errorMessage
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    Text("Save")
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
            }
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
    }
}
