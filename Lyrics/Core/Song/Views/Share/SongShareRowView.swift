//
//  SongShareRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/2/24.
//

import SwiftUI

struct SongShareRowView: View {
    let user: User
    @Binding var selectedUsers: [UserToShare]
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(user.username)
                    .font(.body.weight(.semibold))
                Text("#" + user.id!.prefix(4).uppercased())
                    .foregroundColor(.gray)
            }
            .font(.body.weight(.semibold))
            Spacer()
            if selectedUsers.contains(where: { $0.id == user.id ?? "" }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            } else {
                Image(systemName: "circle")
                    .imageScale(.large)
            }
        }
        .padding()
        .background(Material.regular)
        .foregroundColor(.primary)
        .clipShape(Capsule())
    }
}

#Preview {
    SongShareRowView(user: User(email: "email@user.com", username: "username", fullname: "Full Name"), selectedUsers: .constant([UserToShare(id: "id", username: "username", appVersion: "2.3")]))
}
