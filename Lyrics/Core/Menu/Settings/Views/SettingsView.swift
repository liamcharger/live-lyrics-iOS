//
//  SettingsView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var user: User
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var enableWordCount: Bool
    @State private var isExplicit: Bool
    @State private var songSubtitle: String?
    @State private var wordCountStyle: String?
    @State private var metronomeStyle: [String] = []
    
    @ObservedObject private var settingsViewModel = SettingsViewModel.shared
    
    private func footerText(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 16))
            .foregroundStyle(.gray)
            .padding(.horizontal)
    }
    
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
                Button {
                    dismiss()
                } label: {
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
                VStack(spacing: 20) {
                    VStack(alignment: .leading) {
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
                            .rowCapsule()
                        }
                    }
                    VStack(alignment: .leading) {
                        HStack(spacing: 7) {
                            Text("Song Subtitle")
                            Spacer()
                            Menu {
                                Button(action: { songSubtitle = "None" }) {
                                    Label("None", systemImage: songSubtitle == "None" ? "checkmark" : "")
                                }
                                Divider()
                                Button(action: { songSubtitle = "Lyrics" }) {
                                    Label("Lyrics", systemImage: songSubtitle == "Lyrics" ? "checkmark" : "")
                                }
                                Button(action: { songSubtitle = "Artist" }) {
                                    Label("Artist", systemImage: songSubtitle == "Artist" ? "checkmark" : "")
                                }
                                Button(action: { songSubtitle = "Date" }) {
                                    Label("Date", systemImage: songSubtitle == "Date" ? "checkmark" : "")
                                }
                            } label: {
                                Text(songSubtitle ?? "Choose an Option")
                                    .foregroundColor(.blue)
                            }
                        }
                        .rowCapsule()
                        footerText("The song subtitle is the text that appears under each song title when in a list.")
                    }
                    VStack(alignment: .leading) {
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
                        .rowCapsule()
                        footerText("Customize the metronome. Checking \"audio\" will enable a click sound, and checking \"vibrations\" will enable beat vibrations.")
                    }
                    VStack(alignment: .leading) {
                        Button {
                            Task {
                                try? await AppStore.sync()
                                
                                dismiss()
                            }
                        } label: {
                            Text("Restore In-App Purchases")
                                .rowCapsule()
                        }
                        footerText("If you've previously made a purchase in Live Lyrics and it's not taking effect, try restoring purchases with the button above.")
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
                        dismiss()
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
