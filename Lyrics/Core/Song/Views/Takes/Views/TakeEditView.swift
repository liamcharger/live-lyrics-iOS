//
//  TakeEditView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/22/24.
//

import SwiftUI

struct TakeEditView: View {
    @Binding var isDisplayed: Bool
    @Binding var titleToUpdate: String
    
    @State private var title = ""
    
    let song: Song
    let take: Take
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Take")
                    .font(.title.weight(.bold))
                Spacer()
                SheetCloseButton(isPresented: $isDisplayed)
            }
            .padding()
            Divider()
            ScrollView {
                CustomTextField(text: $title, placeholder: "Title")
                    .focused($isFocused)
                    .padding()
            }
            Divider()
            Button(action: {
                TakesViewModel.shared.updateTake(take, song: song, title: title)
                isDisplayed = false
                titleToUpdate = title
            }) {
                Text(NSLocalizedString("save", comment: "Save"))
                    .frame(maxWidth: .infinity)
                    .modifier(NavButtonViewModifier())
            }
            .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding()
        }
        .onAppear {
            isFocused = true
            title = take.title ?? ""
        }
    }
}
