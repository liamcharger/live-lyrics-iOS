//
//  LiveStagesView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/26/24.
//

import SwiftUI

struct LiveStagesView: View {
    @ObservedObject var stagesViewModel = LiveStagesViewModel.shared
    
    @State var stageSongs: [StageSong] = [
        StageSong(id: UUID().uuidString, title: "Song 1", artist: "Jill Joel", uid: "myuid"),
        StageSong(id: UUID().uuidString, title: "Song 2", artist: "Jack Johnson", uid: "myuid"),
        StageSong(id: UUID().uuidString, title: "Song 3", artist: "Billy Bob Jr.", uid: "myuid")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Update on 'collab' branch CustomNavBar
            CustomNavBar(title: NSLocalizedString("live_stages", comment: ""), navType: .Auth, folder: nil, showBackButton: true, isEditing: .constant(false))
                .padding()
            Divider()
            if stagesViewModel.isConnectedToStage {
                ScrollView {
                    VStack(spacing: 14) {
                        HStack {
                            Button {
                                
                            } label: {
                                VStack(spacing: 7) {
                                    FAText(iconName: "pen-to-square", size: 24)
                                    Text(NSLocalizedString("add_song_to_queue", comment: ""))
                                        .font(.body.weight(.medium))
                                }
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                            }
                            Button {
                                
                            } label: {
                                VStack(spacing: 7) {
                                    FAText(iconName: "square-arrow-right", size: 24)
                                    Text(NSLocalizedString("leave_stage", comment: ""))
                                        .font(.body.weight(.medium))
                                }
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Material.regular)
                                .foregroundColor(.red)
                                .cornerRadius(22)
                            }
                        }
                        .frame(height: 110)
                        VStack {
                            ListHeaderView(title: "Song Requests")
                            ForEach(stageSongs, id: \.id) { song in
                                ListRowView(isEditing: .constant(false), title: song.title, subtitle: song.artist)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 3) {
                    Spacer()
                    Text(NSLocalizedString("not_joined_any_stages", comment: ""))
                        .font(.title.weight(.bold))
                        .multilineTextAlignment(.center)
                    VStack {
                        Button {
                            stagesViewModel.isConnectedToStage = true
                        } label: {
                            HStack(spacing: 5) {
                                FAText(iconName: "link", size: 18)
                                Text(NSLocalizedString("join_a_stage", comment: ""))
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        Button {
                            
                        } label: {
                            HStack(spacing: 5) {
                                FAText(iconName: "pen-to-square", size: 18)
                                Text(NSLocalizedString("create_a_stage", comment: ""))
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding()
                    Spacer()
                    // TODO: add "Tip"
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    LiveStagesView()
}
