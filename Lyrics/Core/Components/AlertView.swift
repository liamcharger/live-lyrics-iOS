//
//  AlertView.swift
//  Lyrics
//
//  Created by Liam Willey on 12/15/24.
//

import SwiftUI

struct AlertButton {
    let title: String
    let action: () -> Void
}

// Don't name this struct "Alert" because it will confuse the compiler with SwiftUI.Alert
struct AlertViewAlert {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
}

struct AlertView: View {
    let alert: AlertViewAlert
    let primaryButton: AlertButton
    let secondaryButton: AlertButton?
    
    init(_ alert: AlertViewAlert, primary primaryButton: AlertButton, secondary secondaryButton: AlertButton? = nil) {
        self.alert = alert
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 18) {
                FAText(iconName: alert.icon, size: 60)
                    .foregroundStyle(alert.accent)
                Text(alert.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.largeTitle.weight(.bold))
                Text(alert.subtitle)
                    .font(.system(size: 20))
            }
            .multilineTextAlignment(.center)
            .frame(maxHeight: .infinity, alignment: .center)
            Spacer()
            VStack(spacing: 12) {
                LiveLyricsButton(primaryButton.title, showProgressIndicator: .constant(false)) {
                    primaryButton.action()
                }
                if let secondaryButton {
                    Button {
                        secondaryButton.action()
                    } label: {
                        Text(secondaryButton.title)
                    }
                }
            }
        }
        .padding()
    }
}
