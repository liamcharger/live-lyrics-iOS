//
//  SongShareView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/2/24.
//

import SwiftUI

struct ShareView: View {
    @Environment(\.presentationMode) var presMode
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @Binding var isDisplayed: Bool
    @State var selectedUsers: [String] = []
    @State var searchText = ""
    @State var collaborate = false
    @State var firstSearch = true
    
    @State var selectedUser: User?
    
    let song: Song?
    let folder: Folder?
    let networkManager = NetworkManager.shared
    
    var disabled: Bool {
        selectedUsers.isEmpty || !networkManager.getNetworkState()
    }
    
    init(isDisplayed: Binding<Bool>, song: Song? = nil, folder: Folder? = nil) {
        self._isDisplayed = isDisplayed
        self.song = song
        self.folder = folder
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Share")
                    .font(.title.weight(.bold))
                Spacer()
                Button {
                    if let user = selectedUser, let currentUser = authViewModel.currentUser {
                        authViewModel.sendInviteToUser(request: {
                            let timestamp = Date()
                            let from = currentUser.id ?? ""
                            let to = selectedUsers
                            let type = collaborate ? "collaborate" : "copy"
                            
                            if let song = song {
                                return ShareRequest(timestamp: timestamp, from: from, to: to, contentId: song.id ?? "", contentType: "song", type: type)
                            } else if let folder = folder {
                                return ShareRequest(timestamp: timestamp, from: from, to: to, contentId: folder.id ?? "", contentType: "folder", type: type)
                            }
                            // Should never be executed
                            return ShareRequest(timestamp: timestamp, from: from, to: to, contentId: "", contentType: "", type: type)
                        }()) { error in
                            if let error = error {
                                print(error.localizedDescription)
                                return
                            }
                            presMode.wrappedValue.dismiss()
                        }
                    }
                } label: {
                    Text("Invite" + (selectedUsers.isEmpty ? "" : " " + String(selectedUsers.count)))
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .font(.body.weight(.semibold))
                        .clipShape(Capsule())
                }
                .opacity(disabled ? 0.5 : 1.0)
                .disabled(disabled)
                SheetCloseButton(isPresented: $isDisplayed)
            }
            .padding()
            Divider()
            // Disabled until full collab features are enabled
//            HStack {
//                Text("Type:")
//                Spacer()
//                Menu {
//                    Button(action: {
//                        collaborate = true
//                    }, label: {
//                        Label("Collaborate", systemImage: collaborate ? "checkmark"  : "")
//                    })
//                    Button(action: {
//                        collaborate = false
//                    }, label: {
//                        Label("Send Copy", systemImage: !collaborate ? "checkmark"  : "")
//                    })
//                } label: {
//                    HStack(spacing: 4) {
//                        Text(collaborate ? "Collaborate" : "Send Copy")
//                        Image(systemName: "chevron.down")
//                    }
//                }
//            }
//            .padding()
//            Divider()
            if networkManager.getNetworkState() {
                CustomSearchBar(text: $searchText, imageName: "magnifyingglass", placeholder: "Search by username...")
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        firstSearch = false
                        if searchText == "" {
                            firstSearch = true
                            authViewModel.users = []
                        } else {
                            authViewModel.fetchUsers(username: searchText)
                        }
                    }
                    .padding()
                Divider()
                if authViewModel.isLoadingUsers {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if !authViewModel.users.isEmpty {
                        ScrollView {
                            VStack {
                                ForEach(authViewModel.users.indices, id: \.self) { index in
                                    let user = authViewModel.users[index]
                                    
                                    Button {
                                        selectedUser = user
                                        if selectedUsers.contains(user.id ?? "") {
                                            selectedUsers.remove(at: index)
                                        } else {
                                            selectedUsers.append(user.id ?? "")
                                        }
                                    } label: {
                                        SongShareRowView(user: user, selectedUsers: $selectedUsers)
                                    }
                                }
                            }
                            .padding()
                        }
                    } else {
                        FullscreenMessage(imageName: firstSearch ? "magnifyingglass" : "person.slash", title: {
                            if firstSearch {
                                if let song = song {
                                    return "Search for a user by their username to share '\(song.title)'."
                                } else if let folder = folder {
                                    return "Search for a user by their username to share '\(folder.title)'."
                                } else {
                                    return "Search for a user by their username to share."
                                }
                            } else {
                                return "It doesn't look like there are any users with that username."
                            }
                        }(), spaceNavbar: true)
                    }
                }
            } else {
                FullscreenMessage(imageName: "wifi.slash", title: "Please connect to the internet to share songs.", spaceNavbar: true)
            }
        }
    }
}

struct FullscreenMessage: View {
    let imageName: String
    let title: String
    let spaceNavbar: Bool?
    
    init(imageName: String, title: String, spaceNavbar: Bool? = nil) {
        self.imageName = imageName
        self.title = title
        self.spaceNavbar = spaceNavbar
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: imageName)
                .font(.system(size: 35).weight(.semibold))
            Text(title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            Spacer()
            if spaceNavbar != nil {
                Spacer()
                    .frame(height: 35)
            }
        }
        .padding()
        .foregroundColor(.gray)
    }
}

#Preview {
    ShareView(isDisplayed: .constant(true), song: Song.song)
}
