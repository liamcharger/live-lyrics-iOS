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
    
    var processedUrl: String {
        if url.lowercased().hasPrefix("http://") || url.lowercased().hasPrefix("https://") {
            return url
        } else {
            return "https://\(url)"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Demo")
                    .font(.title.weight(.bold))
                Spacer()
                SheetCloseButton {
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
                        guard let url = URL(string: processedUrl) else { return }
                        
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
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 7) {
                                Spacer()
                                Text("Delete")
                                Spacer()
//                                Image(systemName: "trash")
                            }
                            .font(.body.weight(.semibold))
                        }
                    }
                    .padding()
                    .foregroundColor(.red)
                    .background(Material.regular)
                    .clipShape(Capsule())
                }
                LiveLyricsButton("Save") {
                    songViewModel.updateDemo(for: song, url: processedUrl) {
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
            url = demo.url
        }
    }
}
