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
    
    @State var title = ""
    @State var lyrics = ""
    @State var errorMessage = ""
    
    @State var view2 = false
    @State var showError = false
    @State var showInfo = false
    @State var canDismissProgrammatically = false
    @State var showAddRoleSheet = false
    
    @State var selectedRole: BandRole?
    
    @Binding var isDisplayed: Bool
    @Binding var createdId: String
    
    @FocusState var isFocused: Bool
    
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
                self.view2 = false
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
                SheetCloseButton(isPresented: $isDisplayed)
            }
            .padding()
            Divider()
            Spacer()
            VStack {
                TextField(NSLocalizedString("title", comment: ""), text: $title)
                    .padding(14)
                    .background(Material.regular)
                    .clipShape(Capsule())
                    .cornerRadius(10)
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
            Button(action: {view2.toggle()}, label: {
                HStack {
                    Spacer()
                    Text("Continue")
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
            })
            .sheet(isPresented: $view2) {
                nextView
            }
            .onChange(of: view2) { newValue in
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
        .bottomSheet(isPresented: $showAddRoleSheet, detents: [.medium()]) {
            BandMemberAddRoleView(member: nil, band: nil, selectedRole: $selectedRole)
        }
        .onAppear {
            isFocused = true
        }
    }
    
    var nextView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Enter the lyrics for the variation.")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                SheetCloseButton(isPresented: $view2)
            }
            .padding()
            Divider()
            TextEditor(text: $lyrics)
                .padding(.horizontal)
                .focused($isFocused)
            Divider()
            Button(action: {
                if lyrics.isEmpty {
                    showInfo.toggle()
                } else {
                    createVariation()
                }
            }, label: {
                HStack {
                    Spacer()
                    Text("Continue")
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
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
