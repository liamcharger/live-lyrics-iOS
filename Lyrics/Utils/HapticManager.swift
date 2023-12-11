//
//  HapticManager.swift
//  Lyrics
//
//  Created by Liam Willey on 8/18/23.
//

import Foundation
import UIKit

fileprivate final class HapticManager {
    static let shared = HapticManager()
    
    private let feedback = UINotificationFeedbackGenerator()
    
    private init() {}
    
    func trigger(_ notification: UINotificationFeedbackGenerator.FeedbackType) {
        feedback.notificationOccurred(notification)
    }
    
    func impact(_ impact: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impact = UIImpactFeedbackGenerator(style: impact)
        impact.impactOccurred()
    }
}

func hapticByType(_ notification: UINotificationFeedbackGenerator.FeedbackType) {
    HapticManager.shared.trigger(notification)
}

func hapticByStyle(_ impact: UIImpactFeedbackGenerator.FeedbackStyle) {
    HapticManager.shared.impact(impact)
}
