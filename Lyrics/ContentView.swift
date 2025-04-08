//
//  ContentView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AuthViewModel.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    @State private var showWhatsNew = false
    
    // Use AppStorage as an easy way to update these vars from outside the view
    @AppStorage(showNewSongKey) private var showNewSong = false
    @AppStorage(showNewFolderKey) private var showNewFolder = false
    
    var body: some View {
        VStack {
            if showWhatsNew {
                ShowWhatsNew(isDisplayed: $showWhatsNew)
            } else {
                if viewModel.userSession == nil {
                    ChooseAuthView()
                } else {
                    MainView()
                        // Add these sheets at the top level so they can be called from other views
                        .sheet(isPresented: $showNewFolder) {
                            NewFolderView(isDisplayed: $showNewFolder)
                        }
                        .sheet(isPresented: $showNewSong) {
                            NewSongView(isDisplayed: $showNewSong)
                        }
                }
            }
        }
        .onAppear {
            // Check if the user has just updated the app or has just opened the app for the first time
            notificationManager.checkForUpdate { isNewVersion in
                if isNewVersion {
                    showWhatsNew = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
