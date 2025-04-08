//
//  CustomNavBar.swift
//  Lyrics
//
//  Created by Liam Willey on 10/23/23.
//

import SwiftUI

enum NavBarEnum {
    case home
    case detail
    case recentlyDeleted
    case auth
}

struct CustomNavBar: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var mainViewModel = MainViewModel.shared
    @ObservedObject private var networkManager = NetworkManager.shared
    
    private let title: String
    private let view: NavBarEnum
    private let showBackButton: Bool
    
    @State private var showOfflineAlert = false
    
    @Binding var showCollapsedNavBar: Bool
    @Binding var showCollapsedNavBarTitle: Bool
    
    @AppStorage(showNewSongKey) var showNewSong = false
    @AppStorage(showNewFolderKey) var showNewFolder = false
    
    init(_ title: String, for view: NavBarEnum = .detail, showBackButton: Bool = true, collapsed: Binding<Bool>, collapsedTitle: Binding<Bool>) {
        self.title = title
        self.view = view
        self.showBackButton = showBackButton
        self._showCollapsedNavBar = collapsed
        self._showCollapsedNavBarTitle = collapsedTitle
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if showBackButton {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .padding()
                        .font(.body.weight(.semibold))
                        .background(Material.regular)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                }
            }
            Group {
                if showCollapsedNavBarTitle {
                    HStack(spacing: 9) {
                        Text(title)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 28, design: .rounded).weight(.bold))
                        /*
                         if !networkManager.getNetworkState() && navType == .home { // Only show in the home view
                         Button {
                         showOfflineAlert = true
                         } label: {
                         Image(systemName: "wifi.slash")
                         .font(.system(size: 16).weight(.medium))
                         .foregroundStyle(Color.red)
                         }
                         }
                         */
                    }
                } else if view == .home && !networkManager.getNetworkState() || mainViewModel.updateAvailable {
                    if !networkManager.getNetworkState() {
                        Button {
                            showOfflineAlert = true
                        } label: {
                            HStack(spacing: 7) {
                                FAText(iconName: "wifi-slash", size: 18)
                                Text(NSLocalizedString("youre_offline", comment: ""))
                            }
                            .padding(13)
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                    } else if mainViewModel.updateAvailable {
                        Button {
                            if let url = URL(string: "https://apps.apple.com/app/id6449195237") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 7) {
                                FAText(iconName: "download", size: 18)
                                Text(NSLocalizedString("update_available", comment: ""))
                            }
                            .padding(13)
                            .background(Color.blue.opacity(0.9))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .transition(.opacity)
            Spacer()
            HStack(spacing: 8) {
                switch view {
                case .home:
                    if showCollapsedNavBar {
                        Button {
                            mainViewModel.showProfileView = true
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
                        }
                    } else {
                        Button {
                            showNewFolder = true
                        } label: {
                            FAText(iconName: "folder-plus", size: 20)
                                .modifier(NavBarRowViewModifier())
                        }
                        Button {
                            showNewSong = true
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
                        }
                    }
                case .recentlyDeleted, .auth, .detail:
                    EmptyView()
                }
            }
            .transition(.opacity)
        }
        .padding()
        .alert(isPresented: $showOfflineAlert) {
            Alert(title: Text("youre_offline"), message: Text("some_features_may_not_work_expectedly"), dismissButton: .cancel(Text("OK")))
        }
    }
}

#Preview {
    CustomNavBar("Home", for: .home, showBackButton: true, collapsed: .constant(false), collapsedTitle: .constant(true))
}
