//
//  SongVariationManageView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/6/24.
//

import SwiftUI

struct SongVariationManageView: View {
    let song: Song
    
    @Binding var isDisplayed: Bool
    @Binding var lyrics: String
    @Binding var selectedVariation: SongVariation?
    @Binding var songVariations: [SongVariation]
    
    @State var showDeleteSheet = false
    @State var showSongVariationEditView = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Variations")
                    .font(.title.weight(.bold))
                Spacer()
                SheetCloseButton(isPresented: $isDisplayed)
            }
            .padding()
            Divider()
            ScrollView {
                VStack {
                    ForEach(songVariations, id: \.id) { variation in
                        if variation.title == "noVariation" {
                            LoadingView()
                        } else {
                            HStack(spacing: 6) {
                                Text(variation.title)
                                Spacer()
                                Button {
                                    selectedVariation = variation
                                    showSongVariationEditView = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .padding(12)
                                        .font(.body.weight(.semibold))
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                .sheet(isPresented: $showSongVariationEditView, onDismiss: {selectedVariation = nil}) {
                                    if let variation = selectedVariation {
                                        SongVariationEditView(song: song, variation: variation, isDisplayed: $showSongVariationEditView)
                                    }
                                }
                                Button {
                                    selectedVariation = variation
                                    showDeleteSheet = true
                                } label: {
                                    Image(systemName: "trash")
                                        .padding(12)
                                        .font(.body.weight(.semibold))
                                        .background(Color.red)
                                        .foregroundColor(.primary)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(12)
                            .background(Material.regular)
                            .cornerRadius(18)
                        }
                    }
                }
                .padding()
            }
        }
        .confirmationDialog("Delete Variation", isPresented: $showDeleteSheet) {
            Button("Delete", role: .destructive) {
                if let selectedVariation = selectedVariation {
                    SongViewModel.shared.deleteSongVariation(song, variation: selectedVariation)
                    self.lyrics = song.lyrics
                    self.selectedVariation = nil
                }
            }
            Button("Cancel", role: .cancel) {
                self.selectedVariation = nil
            }
        } message: {
            Text("Are you sure you want to delete the variation '" + (selectedVariation?.title ?? "") + "'?")
        }
    }
}
