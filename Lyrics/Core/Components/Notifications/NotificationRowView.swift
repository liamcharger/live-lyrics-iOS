//
//  NotificationRowView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/22/23.
//

import SwiftUI

struct NotificationRowView: View {
    let title: String
    let subtitle: String
    let imageName: String
    
    @Binding var notificationStatus: NotificationStatus?
    @Binding var isDisplayed: Bool
    
    @State var arrowOffset: CGFloat = 0
    @State var timer: Timer? = nil
    
    @State var isDisabled = true
    @State var showNotificationDetailView = false
    
    @State var truncatedSubtitle: String = ""
    @State var fullSubtitle: String = ""
    
    @Environment(\.colorScheme) var colorScheme
    
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
                self.isDisplayed = true
            }
        }
    }
    
    init(title: String, subtitle: String, imageName: String, notificationStatus: Binding<NotificationStatus?>, isDisplayed: Binding<Bool>) {
        self.title = title
        self.imageName = imageName
        self.subtitle = subtitle
        
        if subtitle.count > 120 {
            self.truncatedSubtitle = String(subtitle.prefix(117)) + "..."
            self.isDisabled = false
        } else {
            self.truncatedSubtitle = subtitle
            self.isDisabled = true
        }
        self.fullSubtitle = subtitle
        
        self._notificationStatus = notificationStatus
        self._isDisplayed = isDisplayed
    }
    
    var body: some View {
        Group {
            if notificationStatus == .updateAvailable {
                HStack {
                    Button(action: {
                        withAnimation(.bouncy(extraBounce: 0.1)) {
                            arrowOffset = -8
                        }
                        withAnimation(.bouncy(extraBounce: 0.1)) {
                            arrowOffset = 8
                        }
                        hapticByType(.success)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.bouncy(extraBounce: 0.1)) {
                                arrowOffset = 0
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
                            Text(truncatedSubtitle)
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
    }
    
    var label: some View {
        HStack(spacing: 9) {
            Button(action: {showNotificationDetailView = true}) {
                HStack(spacing: 12) {
                    Image(systemName: imageName)
                        .font(.system(size: 30).weight(.medium))
                        .scaleEffect(arrowOffset)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.primary)
                        Text(truncatedSubtitle)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .disabled(isDisabled)
            .bottomSheet(isPresented: $showNotificationDetailView, detents: [.medium()]) {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: imageName)
                            .font(.system(size: 26).weight(.medium))
                        Text(title)
                            .font(.system(size: 26, design: .rounded).weight(.bold))
                        Spacer()
                        Button(action: {showNotificationDetailView = false}) {
                            Image(systemName: "chevron.down")
                                .imageScale(.medium)
                                .padding(12)
                                .padding(.top, 2)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                                .background(Material.regular)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    Divider()
                    ScrollView {
                        Text(fullSubtitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
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
