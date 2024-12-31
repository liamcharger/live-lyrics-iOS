//
//  SongVariationManageView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/6/24.
//

import SwiftUI

struct SongVariationManageView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    
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
                CloseButton {
                    isDisplayed = false
                }
            }
            .padding()
            Divider()
            if songViewModel.isLoadingVariations || songVariations.isEmpty {
                FullscreenMessage(imageName: "circle.slash", title: NSLocalizedString("no_variations_for_song", comment: ""), spaceNavbar: true, isLoading: songViewModel.isLoadingVariations)
            } else {
                ScrollView {
                    VStack {
                        ForEach(songVariations, id: \.id) { variation in
                            if variation.title != SongVariation.defaultId {
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
                                        } else {
                                            LoadingFailedView()
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
                                            .foregroundColor(.white)
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(12)
                                .background(Material.regular)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .confirmationDialog("Delete Variation", isPresented: $showDeleteSheet) {
            Button("Delete", role: .destructive) {
                if let selectedVariation = selectedVariation {
                    self.songViewModel.deleteSongVariation(song, variation: selectedVariation)
                    self.lyrics = song.lyrics
                    self.selectedVariation = nil
                }
            }
            Button("Cancel", role: .cancel) {
                self.selectedVariation = nil
            }
        } message: {
            Text("Are you sure you want to delete the variation \"\(selectedVariation?.title ?? "")\"?")
        }
    }
}
