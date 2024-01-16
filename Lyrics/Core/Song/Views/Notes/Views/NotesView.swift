//
//  NotesView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/28/23.
//

import SwiftUI
import FASwiftUI
import TipKit

struct NotesView: View {
    // Let vars
    let song: Song
    
    // FocusState vars
    @FocusState var isInputActive: Bool
    
    // Object vars
    @Environment(\.presentationMode) var presMode
    @ObservedObject var viewModel: NotesViewModel
    
    // AppStorage vars
    @AppStorage(showNotesDescKey) var showNotesTip = true
    
    init(song: Song) {
        self.song = song
        self.viewModel = NotesViewModel(song: song)
        
        self.viewModel.fetchNotesForInit(song: song)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Notes")
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
            .padding([.leading, .top, .trailing], 5)
            .padding([.leading, .top, .trailing])
            if #available(iOS 17, *) {
                TipView(NotesViewTip())
                    .padding([.top, .horizontal])
            }
            Divider()
                .padding(.top)
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                TextEditor(text: $viewModel.notes)
                    .padding(.leading)
                    .focused($isInputActive)
            }
        }
        .onDisappear {
            viewModel.updateNotes(song, notes: viewModel.notes)
        }
    }
}

#Preview {
    NotesView(song: Song.song)
}
