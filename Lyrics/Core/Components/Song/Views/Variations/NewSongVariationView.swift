//
//  NewSongView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import SwiftUI
import BottomSheet

struct NewSongVariationView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @State private var title = ""
    @State private var lyrics = ""
    @State private var errorMessage = ""
    
    @State private var showAddLyricsView = false
    @State private var showError = false
    @State private var showInfo = false
    @State private var canDismissProgrammatically = false
    @State private var showAddRoleSheet = false
    @State private var showProgressButton = false
    
    @State private var selectedRole: BandRole?
    
    @Binding var isDisplayed: Bool
    @Binding var createdId: String
    
    @FocusState private var isFocused: Bool
    
    let song: Song
    
    func createVariation() {
        songViewModel.createSongVariation(song: song, lyrics: lyrics, title: title, role: selectedRole) { error, createdId in
            if let error = error {
                print(error.localizedDescription)
                self.errorMessage = error.localizedDescription
                self.showError = true
            } else {
                self.createdId = createdId
                self.canDismissProgrammatically = true
                self.showAddLyricsView = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Enter some details for your new variation.")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                CloseButton {
                    isDisplayed = false
                }
            }
            .padding()
            Divider()
            Spacer()
            VStack {
                CustomTextField(text: $title, placeholder: NSLocalizedString("title", comment: ""), image: "character.cursor.ibeam")
                    .focused($isFocused)
                Button {
                    showAddRoleSheet = true
                } label: {
                    HStack {
                        Text(selectedRole?.name ?? "Add a Role")
                        Spacer()
                        FAText(iconName: selectedRole?.icon ?? "plus", size: 18)
                    }
                    .padding()
                    .background(Material.regular)
                    .clipShape(Capsule())
                    .cornerRadius(10)
                }
            }
            .padding()
            Spacer()
            Divider()
            LiveLyricsButton("Continue", showProgressIndicator: .constant(false), action: { showAddLyricsView = true })
                .sheet(isPresented: $showAddLyricsView) {
                    variationLyricsView
                }
                .onChange(of: showAddLyricsView) { newValue in
                    if !newValue {
                        if canDismissProgrammatically {
                            isDisplayed = false
                        }
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .padding()
        }
        .bottomSheet(isPresented: $showAddRoleSheet, detents: [.medium(), .large()]) {
            BandMemberAddRoleView(member: nil, band: nil, selectedRole: $selectedRole)
        }
        .onAppear {
            isFocused = true
        }
    }
    
    var variationLyricsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Enter the lyrics for the variation.")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                CloseButton {
                    showAddLyricsView = false
                }
            }
            .padding()
            Divider()
            TextEditor(text: $lyrics)
                .padding(.horizontal)
                .focused($isFocused)
            Divider()
            LiveLyricsButton("Continue", showProgressIndicator: $showProgressButton, action: {
                if lyrics.isEmpty {
                    showInfo.toggle()
                } else {
                    showProgressButton = true
                    createVariation()
                }
            })
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert(isPresented: $showInfo) {
            Alert(title: Text("You need to add lyrics to a variation to create it."), dismissButton: .cancel() )
        }
        .onAppear {
            isFocused = true
        }
    }
}
