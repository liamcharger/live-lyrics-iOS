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
    @Binding var artist: String
    
    @State var errorMessage = ""
    @State var stateArtist = ""
    @State var stateKey = ""
    @State var stateTitle = ""
    
    @State var showError = false
    @State var showDemoEditSheet = false
    @State var showNewDemoSheet = false
    @State var showDeleteConfirmation = false
    
    @State var selectedDemo: DemoAttachment?
    
    var isEmpty: Bool {
        return title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    func update() {
        self.title = stateTitle
        self.key = stateKey
        self.artist = stateArtist
        
        songViewModel.updateSong(song, title: stateTitle, key: stateKey, artist: stateArtist) { success, errorMessage in
            if !success {
                self.showError = true
                self.errorMessage = errorMessage
            }
        }
        dismiss()
    }
    func dismiss() {
        if let folder = mainViewModel.selectedFolder {
            mainViewModel.fetchSongs(folder)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isDisplayed = false
        }
    }
    
    init(song: Song, isDisplayed: Binding<Bool>, title: Binding<String>, key: Binding<String>, artist: Binding<String>) {
        self.song = song
        self._isDisplayed = isDisplayed
        self._title = title
        self._key = key
        self._artist = artist
        
        // We use separate state vars to hold the values because if the user changes a property and doesn't save it, it will still change in the parent view
        self._stateTitle = State(initialValue: title.wrappedValue)
        self._stateArtist = State(initialValue: artist.wrappedValue)
        self._stateKey = State(initialValue: key.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Song")
                    .font(.title.weight(.bold))
                Spacer()
                CloseButton {
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
                                                        
                                                        guard let url = URL(string: demoURL) else { return }
                                                        
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
                                                        selectedDemo = songViewModel.getDemo(from: attachment)
                                                        showDeleteConfirmation = true
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                                .sheet(isPresented: $showDemoEditSheet) {
                                                    if let demo = selectedDemo {
                                                        DemoAttachmentEditView(demo: demo, song: song)
                                                    } else {
                                                        LoadingFailedView()
                                                    }
                                                }
                                                .confirmationDialog("Delete Demo", isPresented: $showDeleteConfirmation) {
                                                    if let demo = selectedDemo {
                                                        Button("Delete", role: .destructive) {
                                                            self.songViewModel.deleteDemoAttachment(demo: demo, for: song) {}
                                                        }
                                                        Button("Cancel", role: .cancel) {
                                                            self.showDeleteConfirmation = false
                                                        }
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
        .onAppear {
            if let demoToEdit = SongDetailViewModel.shared.demoToEdit {
                selectedDemo = demoToEdit
                showDemoEditSheet = true
            }
        }
    }
}
