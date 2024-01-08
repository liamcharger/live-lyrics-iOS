//
//  CustomNavBar.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI
import FASwiftUI

struct CustomNavBar: View {
    @ObservedObject var mainViewModel = MainViewModel()
    
    @Environment(\.presentationMode) var presMode
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    let title: String
    let navType: NavBarEnum
    let folder: Folder?
    let showBackButton: Bool
    
    @Binding var isEditing: Bool
    
    @State var showSheet1 = false
    @State var showSheet2 = false
    @State var showSheet3 = false
    
    @AppStorage(showNewSongKey) var showNewSong = false
    @AppStorage(showNewFolderKey) var showNewFolder = false
    
    var body: some View {
        HStack(spacing: 8) {
            if showBackButton {
                Button(action: {presMode.wrappedValue.dismiss()}, label: {
                    Image(systemName: "chevron.left")
                        .padding()
                        .font(.body.weight(.semibold))
                        .background(Material.regular)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                })
            }
            Text(title)
                .lineLimit(1)
                .font(.system(size: 28, design: .rounded).weight(.bold))
            Spacer()
            switch navType {
            case .HomeView:
                Button {
                    showSheet1.toggle()
                } label: {
                    FAText(iconName: "folder-plus", size: 20)
                        .modifier(NavBarRowViewModifier())
                }
                .sheet(isPresented: $showNewFolder) {
                    NewFolderView(isDisplayed: $showSheet1)
                }
                Button {
                    showSheet2.toggle()
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
            case .DetailView:
                Button {
                    withAnimation(.bouncy(extraBounce: 0.1)) {
                        isEditing.toggle()
                    }
                } label: {
                    Text(isEditing ? "Done" : "Edit")
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .background(Material.regular)
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                Button {
                    showSheet1.toggle()
                } label: {
                    FAText(iconName: "pen-to-square", size: 20)
                        .modifier(NavBarRowViewModifier())
                }
                .sheet(isPresented: $showSheet1) {
                    if let folder = folder {
                        NewSongView(isDisplayed: $showSheet1, folder: folder)
                    } else {
                        NewSongView(isDisplayed: $showSheet1, folder: nil)
                    }
                }
            case .RecentlyDeleted:
                EmptyView()
            case .DefaultSongs:
                Button {
                    showSheet1.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .modifier(NavBarRowViewModifier())
                }
                .sheet(isPresented: $showSheet1) {
                    DefaultSongSearchView()
                }
                .disabled(isEditing)
                .opacity(isEditing ? 0.5 : 1.0)
            }
        }
    }
}

#Preview {
    CustomNavBar(title: "Home", navType: .HomeView, folder: nil, showBackButton: true, isEditing: .constant(true))
}
