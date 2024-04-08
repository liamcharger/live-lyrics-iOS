//
//  ContentView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var storeKitManager: StoreKitManager
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var mainViewModel = MainViewModel.shared
    
    @State private var showWhatsNew = false
    @State private var showChangeToLocal = false
    
    init() {
        mainViewModel.fetchSystemStatus()
    }
    
    var body: some View {
        VStack {
            if showWhatsNew {
                ShowWhatsNew(isDisplayed: $showWhatsNew)
            } else {
                if !(mainViewModel.systemDoc?.isDisplayed ?? false) {
                    if viewModel.userSession == nil {
                        ChooseAuthView()
                            .environmentObject(viewModel)
                    } else {
                        MainView()
                            .environmentObject(viewModel)
                            .environmentObject(storeKitManager)
                    }
                } else {
                    if let systemDoc = mainViewModel.systemDoc {
                        AlertView(title: systemDoc.title ?? "Error", message: systemDoc.subtitle ?? "An unknown error has occured. Please try again later.", imageName: systemDoc.imageName ?? "exclamationmark.triangle", buttonText: systemDoc.buttonText ?? NSLocalizedString("continue", comment: "Continue"))
                    }
                }
            }
        }
        .onAppear {
            notificationManager.checkForUpdate { isNewVersion in
                if isNewVersion {
                    showWhatsNew = true
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
