//
//  NotesView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/28/23.
//

import SwiftUI
import FASwiftUI

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
            if showNotesTip {
                Divider()
                    .padding(.bottom)
                HStack(alignment: .top, spacing: 15) {
                    FAText(iconName: "lightbulb-on", size: 35)
                        .foregroundColor(.blue)
                        .padding(.top, 5)

                    VStack(alignment: .leading, spacing: 7.5) {
                        HStack {
                            Text("Tip")
                                .foregroundColor(.blue)
                                .font(.title3.weight(.semibold))

                            Spacer()

                            Button(action: { showNotesTip = false }) {
                                Image(systemName: "xmark")
                                    .imageScale(.small)
                                    .padding(9)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.blue)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(.blue, lineWidth: 2.5)
                                    }
                            }
                        }

                        Text(NSLocalizedString("notes_tip", comment: "Notes are valuable guides, serving as reminders for crucial details in both practice sessions and performances."))
                            .lineSpacing(1.4)
                    }
                    .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(Color.blue, lineWidth: 2.5)
                )
                .cornerRadius(15)
                .padding(.horizontal)
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
