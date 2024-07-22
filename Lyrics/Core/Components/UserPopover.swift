//
//  UserPopover.swift
//  Lyrics
//
//  Created by Liam Willey on 5/21/24.
//

import SwiftUI

struct UserPopover: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var joinedUsers: [User]?
    @Binding var selectedUser: User?
    
    @State var showRemoveSheet = false
    @State var readOnly = false
    
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var authViewModel = AuthViewModel.shared
    @ObservedObject var networkManager = NetworkManager.shared
    
    let song: Song?
    let folder: Folder?
    let isSongFromFolder: Bool
    
    func songOrFolderUid() -> String {
        if let song = song {
            return song.uid
        }
        if let folder = folder {
            return folder.uid ?? ""
        }
        return ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let user = selectedUser {
                Group {
                    Button(action: {dismiss()}) {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .padding(12)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    VStack(spacing: 10) {
                        Spacer()
                        UserPopoverRowView(user: user, song: song, folder: folder, size: [35: 24])
                        VStack(spacing: 6) {
                            Text(user.fullname)
                                .multilineTextAlignment(.center)
                                .font(.largeTitle.weight(.bold))
                            HStack(spacing: 4) {
                                Text(user.username)
                                    .font(.system(size: 20).weight(.semibold))
                                Text("#" + user.id!.prefix(4).uppercased())
                            }
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                        }
                        if songOrFolderUid() == authViewModel.currentUser?.id ?? "" {
                            VStack(spacing: 6) {
                                HStack(spacing: 7) {
                                    Button {
                                        showRemoveSheet = true
                                    } label: {
                                        HStack(spacing: 7) {
                                            Text("Remove")
                                            FAText(iconName: "square-arrow-right", size: 18)
                                        }
                                        .foregroundColor(.red)
                                        .padding(10)
                                        .padding(.horizontal, 8)
                                        .background(Material.regular)
                                        .clipShape(Capsule())
                                    }
                                    HStack(spacing: 7) {
                                        Text("Read only:")
                                        if mainViewModel.isLoadingSharedMedia {
                                            ProgressView()
                                        } else {
                                            Toggle("", isOn: $readOnly).labelsHidden()
                                        }
                                    }
                                    .foregroundColor(.blue)
                                    .padding(mainViewModel.isLoadingSharedMedia ? 10 : 6)
                                    .padding(.horizontal, 8)
                                    .background(Material.regular)
                                    .clipShape(Capsule())
                                }
                                .disabled(!networkManager.getNetworkState())
                                .opacity(networkManager.getNetworkState() ? 1 : 0.5)
                                if !networkManager.getNetworkState() {
                                    Text("Connect to the internet to edit collaborator permissions.")
                                        .multilineTextAlignment(.center)
                                        .font(.callout)
                                        .foregroundColor(.gray)
                                        .padding(6)
                                }
                            }
                            .padding(12)
                        }
                        Spacer()
                        /* if currentlyEditingUsers.contains(where: {$0 == user.id ?? ""}) {
                         HStack(spacing: 12) {
                         FAText(iconName: "pen", size: 23)
                         .padding(14)
                         .background(Color.blue)
                         .foregroundColor(.white)
                         .clipShape(Circle())
                         VStack(alignment: .leading) {
                         Text(user.username)
                         .font(.body.weight(.semibold))
                         Text("is currently editing this song")
                         }
                         }
                         .padding()
                         .frame(maxWidth: .infinity, alignment: .leading)
                         .background(Material.regular)
                         .foregroundColor(.primary)
                         .clipShape(RoundedRectangle(cornerRadius: 20))
                         */
                    }
                }
            }
        }
        .padding(12)
        .confirmationDialog("Remove Collaborator?", isPresented: $showRemoveSheet) {
            Button("Remove", role: .destructive) {
                if let song = song {
                    SongViewModel.shared.leaveSong(forUid: selectedUser?.id!, song: song)
                } else if let folder = folder {
                    mainViewModel.leaveCollabFolder(forUid: selectedUser?.id!, folder: folder)
                }
                if let joinedUsers = joinedUsers, let userId = selectedUser?.id, let index = joinedUsers.firstIndex(where: { $0.id == userId }) {
                    self.joinedUsers?.remove(at: index)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let isSharedMedia = isSongFromFolder && song != nil
            let itemType = folder == nil ? "song" : "folder"
            let folderMessage = isSharedMedia ? NSLocalizedString("song_is_part_of_folder_and_will_be_left", comment: "") : ""
            
            if let user = selectedUser {
                Text("Are you sure you want to remove \"\(user.username)\" as a collaborator from this \(itemType)? They will immediately lose access. \(folderMessage)")
            }
        }
        .onAppear {
            if let user = selectedUser {
                mainViewModel.fetchSharedObject(user: user, song: song, folder: folder) { sharedSong, sharedFolder in
                    withAnimation(.none) {
                        if let sharedSong = sharedSong {
                            self.readOnly = sharedSong.readOnly ?? false
                        } else if let sharedFolder = sharedFolder {
                            self.readOnly = sharedFolder.readOnly ?? false
                        }
                    }
                }
            }
        }
        .onChange(of: readOnly) { readOnly in
            if let user = selectedUser {
                mainViewModel.updateSharedMediaReadOnly(user: user, song: song, folder: folder, readOnly: readOnly)
            }
        }
    }
}
