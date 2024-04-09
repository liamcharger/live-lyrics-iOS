//
//  NotesView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/28/23.
//

import SwiftUI
import TipKit

struct NotesView: View {
    @Binding var notes: String
    @Binding var isLoading: Bool
    
    @FocusState var isInputActive: Bool
    
    @Environment(\.presentationMode) var presMode
    
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
            .padding()
            if #available(iOS 17, *) {
                TipView(NotesViewTip())
                    .padding([.bottom, .horizontal])
            }
            Divider()
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                ZStack {
                    TextEditor(text: $notes)
                        .padding(.leading, 13)
                        .focused($isInputActive)
                    if notes.isEmpty && !isInputActive {
                        Text("Tap to enter your notes...")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 20).weight(.semibold))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.leading, 17)
                            .padding(.top, 8)
                            .onTapGesture {
                                isInputActive = true
                            }
                    }
                }
            }
        }
        
    }
}
