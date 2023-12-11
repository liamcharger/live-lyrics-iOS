//
//  NotificationRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/22/23.
//

import SwiftUI

struct NotificationRowView: View {
    // Let vars
    @Binding var title: String
    @Binding var subtitle: String
    @Binding var imageName: String
    @Binding var notificationStatus: NotificationStatus?
    
    // State vars
    @State var arrowOffset: CGFloat = 0
    @State private var timer: Timer? = nil
    
    // Binding vars
    @Binding var showNavigationView: Bool
    
    // Functions
    func startTimer() {
        timer?.invalidate()
        
        if notificationStatus == .updateAvailable {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                if let url = URL(string: "https://apps.apple.com/app/id6449195237") {
                    UIApplication.shared.open(url)
                }
            }
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                self.showNavigationView = true
            }
        }
    }
    
    var body: some View {
        if notificationStatus == .updateAvailable {
            HStack {
                Button(action: {
                    withAnimation(.bouncy(extraBounce: 0.1)) {
                        arrowOffset = -8
                    }
                    withAnimation(.bouncy(extraBounce: 0.1)) {
                        arrowOffset = 8 // Move the arrow up
                    }
                    hapticByType(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.bouncy(extraBounce: 0.1)) {
                            arrowOffset = 0 // Reset to the original position
                        }
                    }
                    startTimer()
                }) {
                    Image(systemName: imageName)
                        .font(.system(size: 30).weight(.medium))
                        .offset(y: arrowOffset)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            .padding(.vertical, 10)
        } else {
            HStack {
                ZStack {
                    if notificationStatus == .firebaseNotification {
                        label
                    } else {
                        Button(action: {
                            withAnimation(.bouncy(extraBounce: 0.1)) {
                                arrowOffset = -2
                            }
                            withAnimation(.bouncy(extraBounce: 0.1)) {
                                arrowOffset = 2
                            }
                            hapticByType(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.bouncy(extraBounce: 0.1)) {
                                    arrowOffset = 1
                                }
                            }
                            startTimer()
                        }) {
                            label
                        }
                    }
                }
            }
            .padding(.vertical, 10)
            .onAppear {
                arrowOffset = 1
            }
        }
    }
    
    var label: some View {
        HStack {
            Image(systemName: imageName)
                .font(.system(size: 30).weight(.medium))
                .scaleEffect(arrowOffset)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Button(action: {notificationStatus = nil}) {
                Image(systemName: "xmark")
                    .padding(12)
                    .font(.body.weight(.semibold))
                    .background(Material.regular)
                    .foregroundColor(.primary)
                    .clipShape(Circle())
            }
        }
    }
}
