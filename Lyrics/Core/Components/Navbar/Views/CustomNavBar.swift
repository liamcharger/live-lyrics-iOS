//
//  CustomNavBar.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

struct CustomNavBar: View {
    @ObservedObject var mainViewModel = MainViewModel.shared
    
    @Environment(\.presentationMode) var presMode
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    let title: String
    let navType: NavBarEnum
    let showBackButton: Bool
    
    @Binding var showCollapsedNavBar: Bool
    @Binding var showCollapsedNavBarTitle: Bool
    
    @AppStorage(showNewSongKey) var showNewSong = false
    @AppStorage(showNewFolderKey) var showNewFolder = false
    
    init(title: String, navType: NavBarEnum? = nil, showBackButton: Bool, collapsed: Binding<Bool>, collapsedTitle: Binding<Bool>) {
        self.title = title
        self.navType = navType ?? .detail
        self.showBackButton = showBackButton
        self._showCollapsedNavBar = collapsed
        self._showCollapsedNavBarTitle = collapsedTitle
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
                .opacity(showCollapsedNavBarTitle ? 1 : 0)
            Spacer()
            HStack(spacing: 8) {
                switch navType {
                case .home:
                    if showCollapsedNavBar {
                        Button {
                            mainViewModel.showProfileView.toggle()
                        } label: {
                            FAText(iconName: "user", size: 20)
                                .frame(width: 23, height: 23)
                                .padding(12)
                                .font(.body.weight(.semibold))
                                .background(Material.thin)
                                .clipShape(Capsule())
                                .overlay {
                                    if mainViewModel.notifications.count >= 1 {
                                        Circle()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.blue)
                                            .overlay {
                                                Text(String(mainViewModel.notifications.count))
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundColor(.white)
                                            }
                                            .offset(x: 17, y: -18)
                                    }
                                }
                        }
                        .sheet(isPresented: $mainViewModel.showProfileView) {
                            MenuView(showMenu: $mainViewModel.showProfileView)
                                .environmentObject(storeKitManager)
                        }
                    } else {
                        Button {
                            showNewFolder.toggle()
                        } label: {
                            FAText(iconName: "folder-plus", size: 20)
                                .modifier(NavBarRowViewModifier())
                        }
                        Button {
                            showNewSong.toggle()
                        } label: {
                            FAText(iconName: "pen-to-square", size: 20)
                                .modifier(NavBarRowViewModifier())
                        }
                        Button {
                            mainViewModel.showProfileView.toggle()
                        } label: {
                            FAText(iconName: "user", size: 20)
                                .modifier(NavBarRowViewModifier())
                                .overlay {
                                    if mainViewModel.notifications.count >= 1 {
                                        Circle()
                                            .frame(width: 24, height: 24)
                                            .overlay {
                                                Circle()
                                                    .stroke(Color(.systemBackground), lineWidth: 3)
                                                    .frame(width: 27, height: 27)
                                                    .foregroundColor(.clear)
                                            }
                                            .foregroundColor(.blue)
                                            .overlay {
                                                Text(String(mainViewModel.notifications.count))
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundColor(.white)
                                            }
                                            .offset(x: 17, y: -18)
                                    }
                                }
                        }
                        .sheet(isPresented: $mainViewModel.showProfileView) {
                            MenuView(showMenu: $mainViewModel.showProfileView)
                                .environmentObject(storeKitManager)
                        }
                    }
                case .recentlyDeleted, .auth, .detail:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    CustomNavBar(title: "Home", navType: .home, showBackButton: true, collapsed: .constant(false), collapsedTitle: .constant(true))
}
