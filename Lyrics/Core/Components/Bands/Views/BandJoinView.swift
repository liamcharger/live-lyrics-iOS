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
    @State var showAlert = false
    @State var isButtonLoading = false
    
    @Binding var isPresented: Bool
    @FocusState var isCodeFocused: Bool
    
    var isEmpty: Bool {
        return code.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Join a Band")
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                    Text("To join a band, enter the six digit code from a band administrator.")
                }
                Spacer()
                Button(action: {isPresented = false}) {
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
            Divider()
            Spacer()
            CustomTextField(text: $code, placeholder: NSLocalizedString("Code", comment: ""))
                .focused($isCodeFocused)
                .padding()
            Spacer()
            Divider()
            LiveLyricsButton("Join", showProgressIndicator: $isButtonLoading) {
                isButtonLoading = true
                bandsViewModel.joinBand(code) { success in
                    if success {
                        isPresented = false
                    } else {
                        showAlert = true
                    }
                    isButtonLoading = false
                }
            }
            .padding()
            .disabled(isEmpty)
            .opacity(isEmpty ? 0.5 : 1)
        }
        .onAppear {
            isCodeFocused = true
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(NSLocalizedString("band_with_code_not_found", comment: "")), dismissButton: .cancel())
        }
    }
}
