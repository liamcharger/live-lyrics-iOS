//
//  NotificationRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/22/23.
//

import SwiftUI

struct NotificationRowView: View {
    let notification: Notification
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.imageName ?? "envelope")
                .font(.system(size: 26).weight(.medium))
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 5) {
                Text(notification.title)
                    .font(.system(size: 18).weight(.bold))
                Text(notification.body)
                    .opacity(0.8)
            }
            Spacer()
            Button {
                guard let index = MainViewModel.shared.notifications.firstIndex(where: { $0.id == notification.id }) else { return }
                
                MainViewModel.shared.notifications.remove(at: index)
            } label: {
                Image(systemName: "xmark")
                    .padding(12)
                    .background(Color.materialRegularGray)
                    .foregroundColor(.primary)
                    .font(.body.weight(.medium))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Material.thin)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
