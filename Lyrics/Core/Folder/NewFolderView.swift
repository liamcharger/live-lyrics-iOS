//
//  NewFolderView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import SwiftUI

struct NewFolderView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @State var title = ""
    @State var lyrics = ""
    @State var errorMessage = ""
    
    @State var view2 = false
    @State var view3 = false
    @State var showError = false
    
    @Binding var isDisplayed: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text("Enter a name for your folder.")
                    .font(.title.weight(.bold))
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                SheetCloseButton(isPresented: $isDisplayed)
            }
            .padding()
            .padding(.top)
            Spacer()
            CustomTextField(text: $title, placeholder: "Title")
                .padding()
            Spacer()
            Button(action: {
                songViewModel.createFolder(title: title) { error in
                    if let error = error {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
                    isDisplayed = false
                }
            }, label: {
                HStack {
                    Spacer()
                    Text(NSLocalizedString("continue", comment: "Continue"))
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
            })
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(title.isEmpty ? 0.5 : 1)
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }
}

//struct NewFolderView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewFolderView()
//    }
//}
