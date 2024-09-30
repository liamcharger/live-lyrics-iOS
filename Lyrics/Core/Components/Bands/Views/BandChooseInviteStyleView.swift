//
//  BandChooseInviteStyleView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/25/24.
//

import SwiftUI
import BottomSheet

struct BandChooseJoinStyleView: View {
    @Environment(\.dismiss) var dismiss
    
    let band: Band?
    
    @Binding var showMultipeerSheet: Bool
    
    var body: some View {
        VStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .imageScale(.medium)
                    .padding(12)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                    .background(Material.regular)
                    .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            Text(band != nil ? "How would you like to invite members to this band?" : "How would you like to join this band?")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            Spacer()
            // TODO: improve titles and views
            Button {
                showMultipeerSheet = true
            } label: {
                ListRowView(title: "Over-the-Air", navArrow: "chevron.right", icon: "antenna.radiowaves.left.and.right")
            }
            Button {
                if band == nil {
                    // Show view to enter join code
                } else {
                    // Copy join code
                }
            } label: {
                ListRowView(title: band == nil ? "With a join Code" : "Copy Join Code", navArrow: "chevron.right", icon: "barcode.viewfinder")
            }
            Spacer()
        }
        .padding()
    }
}
