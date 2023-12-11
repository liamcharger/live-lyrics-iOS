//
//  ChangeLogicView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/4/23.
//

import SwiftUI

struct ChangeLogicView: View {
    @ObservedObject var mainViewModel = MainViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var isSaving = false
    @State var showError = false
    
    let persistanceController = PersistenceController()
    
    var body: some View {
        VStack {
            Text("We're changing our database logic.")
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.top)
            Spacer()
            Button(action: {
                mainViewModel.fetchSongs()
                mainViewModel.fetchFolders()
                mainViewModel.fetchRecentlyDeletedSongs()
                
                isSaving = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    persistanceController.saveLocalUser(user: authViewModel.currentUser!)
                    isSaving = false
                }
                
                // Save a second time because it won't save songs the first time
                persistanceController.saveLocalUser(user: authViewModel.currentUser!)
                
                authViewModel.updateLocalStatus(localStatus: true) { success, error_message in
                    if success {
                        dismiss()
                    } else {
                        showError.toggle()
                    }
                }
            }, label: {
                HStack {
                    Spacer()
                    if !isSaving {
                        Text(NSLocalizedString("continue", comment: "Continue"))
                    } else {
                        ProgressView().tint(.white)
                    }
                    Spacer()
                }
                .modifier(NavButtonViewModifier())
                .disabled(isSaving)
            })
        }
        .padding()
//        .interactiveDismissDisabled()
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text("It looks like something went wrong. Please try again."), dismissButton: .cancel(Text("Close"), action: {}))
        }
    }
}

#Preview {
    ChangeLogicView()
        .environmentObject(AuthViewModel())
}
