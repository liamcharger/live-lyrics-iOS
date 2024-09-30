//
//  ContentView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var mainViewModel = MainViewModel()
    
    @State private var showWhatsNew = false
    
    @AppStorage(showNewSongKey) var showNewSong = false
    @AppStorage(showNewFolderKey) var showNewFolder = false
    
    var body: some View {
        VStack {
            if showWhatsNew {
                ShowWhatsNew(isDisplayed: $showWhatsNew)
            } else {
                if viewModel.userSession == nil {
                    ChooseAuthView()
                } else {
                    MainView()
                        .environmentObject(viewModel)
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
