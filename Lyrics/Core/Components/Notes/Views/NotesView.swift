//
//  NotesView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/28/23.
//

import SwiftUI
import TipKit

struct NotesView: View {
    let song: Song?
    let folder: Folder?
    
    @FocusState var isFocused: Bool
    
    @ObservedObject var notesViewModel = NotesViewModel.shared
    
    @Environment(\.presentationMode) var presMode
    
    init(song: Song? = nil, folder: Folder? = nil) {
        self.song = song
        self.folder = folder
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Notes")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                CloseButton {
                    presMode.wrappedValue.dismiss()
                }
            }
            .padding()
            Divider()
            if notesViewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                ZStack {
                    TextEditor(text: $notesViewModel.notes)
                        .padding(.leading, 13)
                        .focused($isFocused)
                    if notesViewModel.notes.isEmpty && !isFocused {
                        Text("Tap to enter your notes...")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 20).weight(.semibold))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.leading, 17)
                            .padding(.top, 8)
                            .onTapGesture {
                                isFocused = true
                            }
                    }
                }
            }
        }
        .onAppear {
            notesViewModel.fetchNotes(song: song, folder: folder)
        }
        .onDisappear {
            if notesViewModel.lastUpdatedNotes != notesViewModel.notes {
                notesViewModel.updateNotes(song: song, folder: folder, notes: notesViewModel.notes)
            }
            
            notesViewModel.stopUpdatingNotes()
        }
    }
}
