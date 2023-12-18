//
//  Extensions.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import Foundation
import SwiftUI

let showWhatsNewKey = "com.chargertech.Lyrics.firstTimeAlertShown"
let firstTimeAlertKey = "com.chargertech.Lyrics.firstTimeAppOpened"
let firstTimeLocalDataKey = "com.chargertech.Lyrics.firstTimeUserHasOpenedAppWithLocal"
let showNotesDesc = "com.chargertech.Lyrics.showNotesDesc"

func hasHomeButton() -> Bool {
    if let keyWindow = UIApplication.shared.windows.first {
        if #available(iOS 11.0, *) {
            // Check safe area insets for bottom inset
            let bottomInset = keyWindow.safeAreaInsets.bottom
            return bottomInset == 0
        } else {
            // For iOS versions earlier than 11, assume it has a home button
            return true
        }
    }
    
    // Default to true if there is any error
    return true
}

extension View {
    @ViewBuilder
    func showTip() -> some View {
        if #available(iOS 17, *) {
            self
                .popoverTip(PlayViewTip(), arrowEdge: .top)
        }
    }
}

extension View {
    @ViewBuilder public func hidden(_ shouldHide: Bool) -> some View {
        switch shouldHide {
        case true: self.hidden()
        case false: self
        }
    }
}

extension Song {
    static let song = Song(id: "noSongs", uid: "", timestamp: Date(), title: "noSongs", lyrics: "", order: 0, size: 0, key: "", notes: "", lineSpacing: 1.0)
}

extension Folder {
    static let folder = Folder(uid: "", timestamp: Date(), title: "noFolders", order: 0)
}

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}
