//
//  NotificationAuthView.swift
//  Lyrics
//
//  Created by Liam Willey on 12/13/24.
//

import SwiftUI

struct NotificationAuthView: View {
    @Environment(\.presentationMode) var presMode
    
    var body: some View {
        VStack {
            VStack(spacing: 18) {
                FAText(iconName: "bell-ring", size: 60)
                    .foregroundStyle(.red)
                Text("Do you want to allow notifications?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.largeTitle.weight(.bold))
                Text("If you enable them, you'll be able to notified when someone shares you a song, or accepts or declines a shared song from you.")
                    .font(.system(size: 20))
            }
            .multilineTextAlignment(.center)
            .frame(maxHeight: .infinity, alignment: .center)
            Spacer()
            VStack(spacing: 12) {
                LiveLyricsButton("Allow Notifications", showProgressIndicator: .constant(false)) {
                    AppDelegate().registerForNotifications()
                }
                Button {
                    presMode.wrappedValue.dismiss()
                } label: {
                    Text("I don't want notifications")
                }
            }
        }
        .padding()
    }
}

#Preview {
    NotificationAuthView()
}
