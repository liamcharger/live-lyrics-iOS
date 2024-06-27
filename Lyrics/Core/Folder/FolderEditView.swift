//
//  FolderEditView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/22/23.
//

import SwiftUI

struct FolderEditView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @Environment(\.presentationMode) var presMode
    
    @Binding var isDisplayed: Bool
    @Binding var title: String
    
    let folder: Folder
    
    @State var text = ""
    @State var errorMessage = ""
    
    @State var showError = false
    
    @FocusState var isFocused: Bool
    
    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(folder: Folder, isDisplayed: Binding<Bool>, title: Binding<String>) {
        self.folder = folder
        self._title = title
        self._text = State(initialValue: folder.title)
        self._isDisplayed = isDisplayed
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Folder")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                SheetCloseButton(isPresented: $isDisplayed)
            }
            .padding()
            Divider()
            Spacer()
            CustomTextField(text: $text, placeholder: NSLocalizedString("title", comment: ""))
                .focused($isFocused)
                .padding(.horizontal)
            Spacer()
            Divider()
            Button {
                songViewModel.updateTitle(folder, title: text) { success, errorMessage in
                    if success {
                        self.title = text
                        self.isDisplayed = false
                        if folder.uid ?? "" != AuthViewModel.shared.currentUser!.id! {
                            MainViewModel.shared.fetchSharedFolders()
                        }
                    } else {
                        self.showError = true
                        self.errorMessage = errorMessage
                    }
                }
            } label: {
                Text("Save")
                    .frame(maxWidth: .infinity)
                    .modifier(NavButtonViewModifier())
            }
            .opacity(isEmpty ? 0.5 : 1.0)
            .disabled(isEmpty)
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
        .onAppear {
            isFocused = true
            text = title
        }
    }
}
