//
//  FolderEditView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/22/23.
//

import SwiftUI

struct FolderEditView: View {
    @ObservedObject var viewModel = SongViewModel()
    @Environment(\.presentationMode) var presMode
    
    @Binding var showProfileView: Bool
    @Binding var title: String
    
    let folder: Folder
    
    @State var text = ""
    @State var errorMessage = ""
    
    @State var showError = false
    
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
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Folder")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                SheetCloseButton(isPresented: $showProfileView)
            }
            .padding()
            Spacer()
            CustomTextField(text: $text, placeholder: "Title")
                .padding(.horizontal)
            Spacer()
            Button {
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
            } label: {
                Text(NSLocalizedString("save", comment: "Save"))
                    .frame(maxWidth: .infinity)
                    .modifier(NavButtonViewModifier())
            }
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
