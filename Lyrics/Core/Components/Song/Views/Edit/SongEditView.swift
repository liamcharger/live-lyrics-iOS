//
//  SongEditView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/18/23.
//

import SwiftUI
import Combine

struct SongEditView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    @Environment(\.presentationMode) var presMode
    @Environment(\.openURL) var openURL
    
    let song: Song
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @Binding var isDisplayed: Bool
    @Binding var title: String
    @Binding var key: String
    @Binding var duration: String
    @Binding var artist: String
    
    @State var errorMessage = ""
    @State var stateArtist = ""
    @State var stateKey = ""
    @State var stateTitle = ""
    @State var stateDuration = ""
    
    @State var showError = false
    @State var showDemoEditSheet = false
    @State var showNewDemoSheet = false
    @State var showDeleteConfirmation = false
    
    @State var selectedDemo: DemoAttachment?
    
    var isEmpty: Bool {
        let isTitleEmpty = title.trimmingCharacters(in: .whitespaces).isEmpty
        let isDurationInvalid = !stateDuration.isEmpty && isInvalidFormat(stateDuration)
        
        return isTitleEmpty || isDurationInvalid
    }
    func update() {
        self.title = stateTitle
        self.key = stateKey
        self.artist = stateArtist
        self.duration = stateDuration
        songViewModel.updateSong(song, title: stateTitle, key: stateKey, artist: stateArtist, duration: stateDuration) { success, errorMessage in
            if !success {
                self.showError = true
                self.errorMessage = errorMessage
            }
        }
        dismiss()
    }
    func isInvalidFormat(_ duration: String) -> Bool {
        let pattern = "^\\d+:\\d+\\d+$"
        return !duration.isEmpty && !(duration.range(of: pattern, options: .regularExpression) != nil)
    }
    func dismiss() {
        if let folder = mainViewModel.selectedFolder {
            mainViewModel.fetchSongs(folder)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isDisplayed = false
        }
    }
    
    init(song: Song, isDisplayed: Binding<Bool>, title: Binding<String>, key: Binding<String>, artist: Binding<String>, duration: Binding<String>) {
        self.song = song
        self._isDisplayed = isDisplayed
        self._title = title
        self._key = key
        self._artist = artist
        self._duration = duration
        
        self._stateTitle = State(initialValue: title.wrappedValue)
        self._stateArtist = State(initialValue: artist.wrappedValue == NSLocalizedString("not_set", comment: "") ? "": artist.wrappedValue)
        self._stateKey = State(initialValue: key.wrappedValue == NSLocalizedString("not_set", comment: "") ? "": key.wrappedValue)
        self._stateDuration = State(initialValue: duration.wrappedValue == NSLocalizedString("not_set", comment: "") ? "": duration.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Song")
                    .font(.title.weight(.bold))
                Spacer()
                SheetCloseButton {
                    presMode.wrappedValue.dismiss()
                }
            }
            .padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack {
                        CustomTextField(text: $stateTitle, placeholder: NSLocalizedString("title", comment: ""))
                        CustomTextField(text: $stateKey, placeholder: NSLocalizedString("Key", comment: ""))
                        CustomTextField(text: $stateArtist, placeholder: NSLocalizedString("Artist", comment: ""))
                        CustomTextField(text: $stateDuration, placeholder: NSLocalizedString("duration", comment: ""))
                    }
                    if let user = authViewModel.currentUser, (!(user.hasPro ?? false) && !(song.demoAttachments ?? []).isEmpty) || (user.hasPro ?? false) {
                            VStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Text("Demo Attachments".uppercased())
                                            .font(.system(size: 16).weight(.bold))
                                        Spacer()
                                        if user.hasPro ?? false {
                                            Button {
                                                showNewDemoSheet = true
                                            } label: {
                                                Image(systemName: "plus")
                                                    .padding(10)
                                                    .font(.body.weight(.medium))
                                                    .background(Color.accentColor)
                                                    .foregroundColor(.white)
                                                    .clipShape(Circle())
                                            }
                                            .sheet(isPresented: $showNewDemoSheet) {
                                                NewDemoAttachmentView(song: song)
                                            }
                                        }
                                    }
                                }
                                if (song.demoAttachments ?? []).isEmpty {
                                    EmptyStateView(state: .demoAttachments)
                                } else {
                                    if let demoAttachments = song.demoAttachments {
                                        LazyVGrid(columns: columns) {
                                            ForEach(demoAttachments, id: \.self) { attachment in
                                                let demo = songViewModel.getDemo(from: attachment)
                                                
                                                Button {
                                                    selectedDemo = demo
                                                    showDemoEditSheet = true
                                                } label: {
                                                    VStack(alignment: .leading, spacing: 12) {
                                                        songViewModel.getDemoIcon(from: demo.icon, size: 22)
                                                            .foregroundColor(demo.color)
                                                        Text(NSLocalizedString(demo.title, comment: ""))
                                                            .font(.system(size: 18).weight(.semibold))
                                                            .frame(maxWidth: 95, alignment: .leading)
                                                            .multilineTextAlignment(.leading)
                                                            .lineLimit(2)
                                                    }
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                                    .frame(minHeight: 80)
                                                    .padding()
                                                    .frame(maxHeight: .infinity)
                                                    .background(Material.thin)
                                                    .foregroundColor(.primary)
                                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                                }
                                                .contextMenu {
                                                    Button {
                                                        let demoURL = songViewModel.getDemo(from: attachment).url
                                                        var processedUrl: String {
                                                            if demoURL.lowercased().hasPrefix("http://") || demoURL.lowercased().hasPrefix("https://") {
                                                                return demoURL
                                                            } else {
                                                                return "https://\(demoURL)"
                                                            }
                                                        }
                                                        guard let url = URL(string: processedUrl) else { return }
                                                        
                                                        openURL(url)
                                                     } label: {
                                                        Label("Open", systemImage: "arrow.up.right.square")
                                                    }
                                                    Button {
                                                        selectedDemo = songViewModel.getDemo(from: attachment)
                                                        showDemoEditSheet = true
                                                    } label: {
                                                        Label("Edit", systemImage: "pencil")
                                                    }
                                                    Button(role: .destructive) {
                                                        showDeleteConfirmation = true
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                                .sheet(isPresented: $showDemoEditSheet) {
                                                    if let demo = selectedDemo {
                                                        DemoAttachmentEditView(demo: demo, song: song)
                                                    }
                                                }
                                                .confirmationDialog("Delete Demo", isPresented: $showDeleteConfirmation) {
                                                    Button("Delete", role: .destructive) {
                                                        self.songViewModel.deleteDemoAttachment(demo: demo, for: song) {}
                                                    }
                                                    Button("Cancel", role: .cancel) {
                                                        self.showDeleteConfirmation = false
                                                    }
                                                } message: {
                                                    Text("Are you sure you want to delete this demo?")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                    }
                    if isInvalidFormat(stateDuration) {
                        Group {
                            Text("The duration is not formatted correctly. Correct formatting, e.g., ") +
                            Text("2:33").font(.body.weight(.bold)) +
                            Text(".")
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                    }
                }
                .padding()
            }
            Divider()
            VStack(spacing: 16) {
                Text("These settings are not specific to song variations.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.gray)
                LiveLyricsButton("Save", action: update)
                    .opacity(isEmpty ? 0.5 : 1.0)
                    .disabled(isEmpty)
            }
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
    }
}
