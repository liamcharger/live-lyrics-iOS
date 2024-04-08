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
                TextEditor(text: $notes)
                    .padding(.leading)
                    .focused($isInputActive)
            }
        }
        
    }
}
