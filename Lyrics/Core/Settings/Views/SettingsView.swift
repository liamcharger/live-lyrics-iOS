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
    
    @State var user: User
    
    @State var errorMessage = ""
    
    @State var showError = false
    @State var enableWordCount: Bool
    @State var isExplicit: Bool
    @State var songSubtitle: String?
    @State var wordCountStyle: String?
    @State var metronomeStyle: [String] = []
    
    @ObservedObject var settingsViewModel = SettingsViewModel.shared
    
    init(user: User) {
        self.user = user
        
        self._enableWordCount = State(initialValue: user.wordCount ?? true)
        self._isExplicit = State(initialValue: user.showsExplicitSongs ?? true)
        self._songSubtitle = State(initialValue: user.showDataUnderSong ?? "None")
        self._wordCountStyle = State(initialValue: user.wordCountStyle ?? "Words")
        self._metronomeStyle = State(initialValue: user.metronomeStyle ?? ["Audio", "Vibrations"])
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Settings")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                Button(action: { presMode.wrappedValue.dismiss() }) {
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
                VStack(spacing: 16) {
                    VStack {
                        HStack(spacing: 7) {
                            Text("Enable\nWord Count")
                            Spacer()
                            Toggle(isOn: $enableWordCount, label: {})
                        }
                        .padding()
                        .background(Material.regular)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .foregroundColor(.primary)
                        if enableWordCount {
                            HStack(spacing: 7) {
                                Text("Word Count Style")
                                Spacer()
                                Menu {
                                    Button(action: { wordCountStyle = "Characters" }) {
                                        Label("Characters", systemImage: wordCountStyle == "Characters" ? "checkmark" : "")
                                    }
                                    Button(action: { wordCountStyle = "Words" }) {
                                        Label("Words", systemImage: wordCountStyle == "Words" ? "checkmark" : "")
                                    }
                                    Button(action: { wordCountStyle = "Spaces" }) {
                                        Label("Spaces", systemImage: wordCountStyle == "Spaces" ? "checkmark" : "")
                                    }
                                    Button(action: { wordCountStyle = "Paragraphs" }) {
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
                        }
                    }
                    VStack {
                        HStack(spacing: 7) {
                            Text("Song Subtitle")
                            Spacer()
                            Menu {
                                Button(action: { songSubtitle = "Show Date" }) {
                                    Label("Date", systemImage: songSubtitle == "Show Date" ? "checkmark" : "")
                                }
                                Button(action: { songSubtitle = "Show Lyrics" }) {
                                    Label("Lyrics", systemImage: songSubtitle == "Show Lyrics" ? "checkmark" : "")
                                }
                                Button(action: { songSubtitle = "Show Artist" }) {
                                    Label("Artist", systemImage: songSubtitle == "Show Artist" ? "checkmark" : "")
                                }
                                Button(action: { songSubtitle = "None" }) {
                                    Label("None", systemImage: songSubtitle == "None" ? "checkmark" : "")
                                }
                            } label: {
                                HStack {
                                    Text(songSubtitle ?? "Choose an Option")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Material.regular)
                        .clipShape(Capsule())
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
                    }
                    VStack {
                        Button {
                            Task {
                                try? await AppStore.sync()
                                presMode.wrappedValue.dismiss()
                            }
                        } label: {
                            Text("Restore In-App Purchases")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Material.regular)
                                .foregroundColor(.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .padding()
            }
            Divider()
            LiveLyricsButton("Save", action: {
                settingsViewModel.updateSettings(user, wordCount: enableWordCount, songSubtitle: songSubtitle ?? "None", wordCountStyle: wordCountStyle ?? "Words", showsExplicitSongs: isExplicit, metronomeStyle: metronomeStyle) { success, errorMessage in
                    if success {
                        presMode.wrappedValue.dismiss()
                    } else {
                        self.showError = true
                        self.errorMessage = errorMessage
                    }
                }
            })
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
    }
}
