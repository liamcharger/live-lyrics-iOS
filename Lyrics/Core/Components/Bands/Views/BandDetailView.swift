//
//  BandDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 9/16/24.
//

import SwiftUI

struct BandDetailView: View {
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    @Binding var band: Band?
    
    var body: some View {
        VStack(spacing: 0) {
            SheetCloseButton {
                band = nil
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding()
            Divider()
            if let band = band {
                ScrollView {
                    VStack(spacing: 22) {
                        VStack(spacing: 14) {
                            VStack {
                                FAText(iconName: "guitar", size: 35)
                                    .padding(24)
                                    .background(Material.regular)
                                    .clipShape(Circle())
                                VStack(spacing: 4) {
                                    Text(band.name)
                                        .multilineTextAlignment(.center)
                                        .font(.largeTitle.weight(.bold))
                                    Text("\(band.members.count) members\(band.members.count == 1 ? "" : "s")")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                }
                            }
                            HeaderActionsView([
                                .init(title: NSLocalizedString("Get Join Code", comment: ""), icon: "link", scheme: .secondary, action: {
                                    
                                }),
                                .init(title: NSLocalizedString("Delete", comment: ""), icon: "trash-can", scheme: .destructive, action: {
                                    
                                })
                            ])
                        }
                        .padding(.top)
                        .padding(.bottom, 6)
                        VStack {
                            ListHeaderView(title: NSLocalizedString("band_members", comment: ""))
                        }
                        VStack {
                            ListHeaderView(title: NSLocalizedString("shared_songs", comment: ""))
                        }
                    }
                    .padding()
                }
            } else {
                ProgressView("loading")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
