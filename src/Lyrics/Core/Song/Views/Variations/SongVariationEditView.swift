//
//  SongVariationEditView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/19/24.
//

import SwiftUI

struct SongVariationEditView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    
    let song: Song
    let variation: SongVariation
    
    @Binding var isDisplayed: Bool
    
    @State var errorMessage = ""
    @State var title = ""
    
    @State var showError = false
    
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func update() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isDisplayed = false
        }
        songViewModel.updateVariation(song: song, variation: variation, title: title)
    }
    
    init(song: Song, variation: SongVariation, isDisplayed: Binding<Bool>) {
        self.song = song
        self.variation = variation
        self._isDisplayed = isDisplayed
        self._title = State(initialValue: variation.title)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Variation")
                    .font(.title.weight(.bold))
                Spacer()
                SheetCloseButton(isPresented: $isDisplayed)
            }
            .padding()
            Divider()
            ScrollView {
                CustomTextField(text: $title, placeholder: "Title")
                    .padding()
            }
            Divider()
            Button(action: update) {
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
    }
}


#Preview {
    SongVariationEditView(song: Song.song, variation: SongVariation.variation, isDisplayed: .constant(true))
}
