//
//  LoadingFailedView.swift
//  Lyrics
//
//  Created by Liam Willey on 12/14/24.
//

import SwiftUI

struct LoadingFailedView: View {
    @Environment(\.presentationMode) var presMode
    
    var body: some View {
        let alert = AlertViewAlert(title: NSLocalizedString("Hmm...we had a problem loading what you requested.", comment: ""), subtitle: NSLocalizedString("Try again in a few minutes, and make sure you're online.", comment: ""), icon: "warning", accent: .yellow)
        let primary = AlertButton(title: NSLocalizedString("Understood", comment: "")) {
            presMode.wrappedValue.dismiss()
        }
        
        AlertView(alert, primary: primary)
    }
}

#Preview {
    LoadingFailedView()
}
