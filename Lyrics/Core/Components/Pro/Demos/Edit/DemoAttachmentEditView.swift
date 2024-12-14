//
//  DemoAttachmentEditView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/7/24.
//

import SwiftUI

struct DemoAttachmentEditView: View {
    @Environment(\.presentationMode) var presMode
    @Environment(\.openURL) var openURL
    
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @State var url = ""
    @State var showDeleteConfirmation = false
    
    let demo: DemoAttachment
    let song: Song
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Demo")
                    .font(.title.weight(.bold))
                Spacer()
                CloseButton {
                    presMode.wrappedValue.dismiss()
                }
            }
            .padding()
            Divider()
            VStack(spacing: 4) {
                Spacer()
                HStack {
                    CustomTextField(text: $url, placeholder: "URL")
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                    Button {
                        guard let url = URL(string: songViewModel.appendPrefix(url)) else { return }
                        
                        openURL(url)
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .padding(14)
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding()
            Divider()
            VStack {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete")
                        .frame(maxWidth: .infinity)
                        .font(.body.weight(.semibold))
                        .padding()
                        .foregroundColor(.red)
                        .background(Material.regular)
                        .clipShape(Capsule())
                }
                LiveLyricsButton("Save") {
                    songViewModel.updateDemo(for: song, oldUrl: demo.url, url: songViewModel.appendPrefix(url)) {
                        presMode.wrappedValue.dismiss()
                    }
                }
            }
            .padding()
        }
        .confirmationDialog("Delete Demo", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                self.songViewModel.deleteDemoAttachment(demo: demo, for: song) {
                    self.presMode.wrappedValue.dismiss()
                }
            }
            Button("Cancel", role: .cancel) {
                self.showDeleteConfirmation = false
            }
        } message: {
            Text("Are you sure you want to delete this demo?")
        }
        .onAppear {
            url = songViewModel.removePrefix(demo.url)
        }
        .onDisappear {
            // Change demo back to nil to avoid a sheet appearing when the song edit view is presented
            SongDetailViewModel.shared.demoToEdit = nil
        }
    }
}
