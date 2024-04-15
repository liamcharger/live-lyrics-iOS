//
//  SongShareRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/2/24.
//

import SwiftUI

struct SongShareRowView: View {
    let user: User
    @Binding var selectedUsers: [String: String]
    
    var body: some View {
        HStack {
            Text(user.username)
                .font(.body.weight(.semibold))
            Spacer()
            if selectedUsers.keys.contains(user.id ?? "") {
                Image(systemName: "checkmark.circle")
            } else {
                Image(systemName: "circle")
            }
        }
        .padding()
        .background(Material.regular)
        .foregroundColor(.primary)
        .clipShape(Capsule())
    }
}

#Preview {
    SongShareRowView(user: User(email: "email@user.com", username: "username", fullname: "Full Name"), selectedUsers: .constant(["key": "uid", "key2": "uid"]))
}
