//
//  BandJoinView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/2/24.
//

import SwiftUI

struct BandJoinView: View {
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    @State var code = ""
    
    @Binding var isPresented: Bool
    @FocusState var isCodeFocused: Bool
    
    var isEmpty: Bool {
        return code.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Join a Band")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.leading)
                Spacer()
                SheetCloseButton(isPresented: $isPresented)
            }
            .padding()
            Divider()
            Spacer()
            VStack(spacing: 14) {
                VStack(spacing: 12) {
                    FAText(iconName: "lock", size: 40)
                    Text("To join a band, enter the six digit code from a band administrator.")
                        .multilineTextAlignment(.center)
                }
                CustomTextField(text: $code, placeholder: NSLocalizedString("Code", comment: ""))
                    .focused($isCodeFocused)
            }
            .padding()
            Spacer()
            Divider()
            Button {
                bandsViewModel.joinBand(code) {
                    isPresented = false
                }
            } label: {
                HStack {
                    Spacer()
                    Text("Join Band")
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
            }
            .padding()
            .disabled(isEmpty)
            .opacity(isEmpty ? 0.5 : 1)
        }
        .onAppear {
            isCodeFocused = true
        }
    }
}
