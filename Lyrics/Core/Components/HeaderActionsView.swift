//
//  HeaderActionsView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/16/24.
//

import SwiftUI

enum HeaderAction {
    case primary
    case primaryAlt
    case secondary
    case destructive
}

struct HeaderActionButton {
    let title: String
    let icon: String
    let scheme: HeaderAction
    let action: () -> Void
}

struct HeaderActionsView: View {
    let buttons: [HeaderActionButton]
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(_ buttons: [HeaderActionButton]) {
        self.buttons = buttons
    }
    
    var body: some View {
        let content = ForEach(buttons, id: \.title) { button in
            Button {
                button.action()
            } label: {
                HStack(spacing: 7) {
                    if button.icon.contains("sf-") {
                        Image(systemName: button.icon.replacingOccurrences(of: "sf-", with: ""))
                            .font(.system(size: 18).weight(.medium))
                    } else {
                        FAText(iconName: button.icon, size: 18)
                    }
                    Text(button.title)
                        .font(.body.weight(.semibold))
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(button.scheme == .primary ? Color.blue : Color.materialRegularGray)
                .foregroundColor({
                    switch button.scheme {
                    case .primary:
                        return .white
                    case .primaryAlt:
                        return .blue
                    case .secondary:
                        return .primary
                    case .destructive:
                        return .red
                    }
                }())
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        
        if buttons.count > 1 {
            LazyVGrid(columns: columns, spacing: 8) {
                content
            }
        } else {
            content
        }
    }
}
