//
//  Haptics.swift
//  Lyrics
//
//  Created by Liam Willey on 8/18/23.
//

import Foundation
import UIKit

func hapticByType(_ notification: UINotificationFeedbackGenerator.FeedbackType) {
    UINotificationFeedbackGenerator().notificationOccurred(notification)
}

func hapticByStyle(_ impact: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: impact).impactOccurred()
}
