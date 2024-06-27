//
//  CustomNavBar.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

struct CustomNavBar: View {
    @ObservedObject var mainViewModel = MainViewModel()
    
    @Environment(\.presentationMode) var presMode
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    let title: String
    let navType: NavBarEnum
    let showBackButton: Bool
    
    @State var showSheet1 = false
    @State var showSheet2 = false
    @State var showSheet3 = false
    
    @AppStorage(showNewSongKey) var showNewSong = false
    @AppStorage(showNewFolderKey) var showNewFolder = false
    
    init(title: String, navType: NavBarEnum? = nil, showBackButton: Bool? = nil) {
        self.title = title
        self.navType = navType ?? .detail
        self.showBackButton = showBackButton ?? true
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if showBackButton {
                Button(action: {
                    presMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "chevron.left")
                        .padding()
                        .font(.body.weight(.semibold))
                        .background(Material.regular)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                })
            }
            Text(title)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .font(.system(size: 28, design: .rounded).weight(.bold))
            Spacer()
            HStack(spacing: 8) {
                switch navType {
                case .home:
                    Button {
                        showNewFolder.toggle()
                    } label: {
                        FAText(iconName: "folder-plus", size: 20)
                            .modifier(NavBarRowViewModifier())
                    }
                    .sheet(isPresented: $showNewFolder) {
                        NewFolderView(isDisplayed: $showNewFolder)
                    }
                    Button {
                        showNewSong.toggle()
                    } label: {
                        FAText(iconName: "pen-to-square", size: 20)
                            .modifier(NavBarRowViewModifier())
                    }
                    .sheet(isPresented: $showNewSong) {
                        NewSongView(isDisplayed: $showNewSong, folder: nil)
                    }
                    Button {
                        showSheet3.toggle()
                    } label: {
                        FAText(iconName: "user", size: 20)
                            .modifier(NavBarRowViewModifier())
                    }
                    .sheet(isPresented: $showSheet3) {
                        MenuView(showMenu: $showSheet3)
                            .environmentObject(storeKitManager)
                    }
                case .recentlyDeleted, .auth, .detail:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    CustomNavBar(title: "Home", navType: .home, showBackButton: true)
}
