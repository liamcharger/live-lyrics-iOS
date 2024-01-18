//
//  FolderEditView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/22/23.
//

import SwiftUI

struct FolderEditView: View {
    // Environment vars
    @ObservedObject var viewModel = SongViewModel()
    @Environment(\.presentationMode) var presMode
    
    // Binding vars
    @Binding var showProfileView: Bool
    @Binding var title: String
    
    let folder: Folder
    
    // State vars
    @State var text = ""
    @State var errorMessage = ""
    
    @State var showError = false
    
    // FocusState vars
    @FocusState var isFocused: Bool
    
    // Standard vars
    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(folder: Folder, showView: Binding<Bool>, title: Binding<String>) {
        self.folder = folder
        self._title = title
        self._text = State(initialValue: folder.title)
        self._showProfileView = showView
    }
    
    var body: some View {
        VStack {
            // MARK: Navbar
            HStack(alignment: .center, spacing: 10) {
                // MARK: User info
                Text("Edit Folder")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                SheetCloseButton(isPresented: $showProfileView)
            }
            .padding()
            Spacer()
            VStack(alignment: .leading, spacing: 15) {
                CustomTextField(text: $text, placeholder: "Title")
                    .focused($isFocused)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Spacer()
                            Button(action: {isFocused = false}, label: {
                                Text("Done")
                            })
                        }
                    }
            }.padding(.horizontal)
            Spacer()
            Button(action: {
                viewModel.updateTitle(folder, title: text) { success in
                    if success {
                        self.title = text
                        showProfileView = false
                    } else {
                        showError.toggle()
                    }
                } completionString: { string in
                    errorMessage = string
                }
            }, label: {
                HStack {
                    Spacer()
                    Text(NSLocalizedString("save", comment: "Save"))
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
            })
            .opacity(isEmpty ? 0.5 : 1.0)
            .disabled(isEmpty)
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
        .onAppear {
            text = title
        }
    }
}
