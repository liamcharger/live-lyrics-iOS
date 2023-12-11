//
//  NotesView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/28/23.
//

import SwiftUI

struct NotesView: View {
    // Let vars
    let song: Song
    
    // FocusState vars
    @FocusState var isInputActive: Bool
    
    // Object vars
    @Environment(\.presentationMode) var presMode
    @ObservedObject var viewModel: NotesViewModel
    
    init(song: Song) {
        self.song = song
        self.viewModel = NotesViewModel(song: song)
        
        self.viewModel.fetchNotesForInit(song: song)
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 10) {
                Text("Notes")
                    .font(.title.weight(.bold))
                Spacer()
                Button(action: {presMode.wrappedValue.dismiss()}) {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color("Color"))
                        .background(Material.regular)
                        .clipShape(Circle())
                }
            }
            .padding([.leading, .top, .trailing], 5)
            .padding([.leading, .top, .trailing])
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                TextEditor(text: $viewModel.notes)
                    .onChange(of: viewModel.notes, perform: { notes in
                        viewModel.updateNotes(song, notes: viewModel.notes)
                    })
                    .padding(.leading)
                    .focused($isInputActive)
            }
        }
    }
}
