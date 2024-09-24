//
//  BandRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import SwiftUI

struct BandRowView: View {
    let band: Band
    
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    @Binding var selectedBand: Band?
    
    @State var loadingMembers = true
    @State var loadingRoles = true
    
    var uid: String {
        return authViewModel.currentUser?.id ?? ""
    }
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(band.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.primary)
                    Text("\(band.members.count) member\(band.members.count == 1 ? "" : "s")")
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onDisappear {
            selectedBand = nil
        }
    }
}
