//
//  BandRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import SwiftUI

struct BandRowView: View {
    let band: Band
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(band.name)
                        .font(.title2.weight(.bold))
                    Text("\(band.members.count) members")
                        .foregroundColor(.gray)
                }
                Spacer()
                // Notes button for band-public notes?
                // TODO: add menu button with actions: leave, etc.
            }
            .padding()
            Divider()
            ScrollView(.horizontal) {
                HStack {
                    // TODO: replace with BandPopoverRowView that displays roles (drummer, guitarist, etc.)
                    UserPopoverRowView(user: User(id: "thisistheid", email: "testingemail@icloud.com", username: "testingusername", fullname: "Untest Fullname"))
                    UserPopoverRowView(user: User(id: "thisistheid", email: "testingemail1@icloud.com", username: "testingusername1", fullname: "Test Fullname"))
                    UserPopoverRowView(user: User(id: "thisistheid", email: "testingemail2@icloud.com", username: "testingusername2", fullname: "Different Fullname"))
                    UserPopoverRowView(user: User(id: "thisistheid", email: "testingemail3@icloud.com", username: "testingusername3", fullname: "A-Different Fullname"))
                }
                .padding()
            }
        }
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            // TODO: load band members with IDs
            
        }
    }
}
