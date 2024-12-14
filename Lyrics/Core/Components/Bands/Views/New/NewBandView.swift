//
//  NewBandView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/2/24.
//

import SwiftUI

struct NewBandView: View {
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    @State var name = ""
    
    @Binding var isPresented: Bool
    @FocusState var isNameFocused: Bool
    
    var isEmpty: Bool {
        return name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Create a New Band")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                CloseButton {
                    isPresented = false
                }
            }
            .padding()
            Divider()
            Spacer()
            VStack {
                CustomTextField(text: $name, placeholder: NSLocalizedString("Name", comment: ""))
                    .focused($isNameFocused)
                // TODO: add more fields like icon (or members?)
            }
            .padding()
            Spacer()
            Divider()
            LiveLyricsButton("Create") {
                bandsViewModel.createBand(name) {
                    isPresented = false
                }
            }
            .padding()
            .disabled(isEmpty)
            .opacity(isEmpty ? 0.5 : 1)
        }
        .onAppear {
            isNameFocused = true
        }
    }
}

#Preview {
    NewBandView(isPresented: .constant(true))
}
