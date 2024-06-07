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
    
    @ObservedObject var authViewModel = AuthViewModel.shared
    @ObservedObject var networkManager = NetworkManager.shared
    
    let song: Song?
    let folder: Folder?
    
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
                    VStack(spacing: 12) {
                        Spacer()
                        Text(user.fullname.components(separatedBy: " ").filter { !$0.isEmpty }.reduce("") { ($0 == "" ? "" : "\($0.first!)") + "\($1.first!)" })
                            .font(.system(size: 35).weight(.semibold))
                            .padding(22)
                            .background(Material.regular)
                            .clipShape(Circle())
                        VStack(spacing: 8) {
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
                                .frame(maxWidth: .infinity)
                                .disabled(!networkManager.getNetworkState())
                                .opacity(networkManager.getNetworkState() ? 1 : 0.5)
                                if !networkManager.getNetworkState() {
                                    Text(NSLocalizedString("connect_internet_remove_collab", comment: ""))
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
                         .cornerRadius(20)
                         */
                    }
                }
            }
        }
        .padding()
        .confirmationDialog("Remove Collaborator?", isPresented: $showRemoveSheet) {
            Button("Remove", role: .destructive) {
                if let song = song {
                    SongViewModel.shared.leaveSong(forUid: selectedUser?.id!, song: song)
                } else if let folder = folder {
                    MainViewModel.shared.leaveCollabFolder(forUid: selectedUser?.id!, folder: folder)
                }
                if let joinedUsers = joinedUsers, let userId = selectedUser?.id, let index = joinedUsers.firstIndex(where: { $0.id == userId }) {
                    self.joinedUsers?.remove(at: index)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let user = selectedUser {
                Text("Are you sure you want to remove \"\(user.username)\" as a collaborator from this \(folder == nil ? "song" : "folder")? They will immediately lose access.")
            }
        }
    }
}
