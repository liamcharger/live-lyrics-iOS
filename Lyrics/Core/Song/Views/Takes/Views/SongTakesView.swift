//
//  SongTakesView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/17/24.
//

import SwiftUI
import AVFoundation

struct SongTakesView: View {
    @Binding var isPresented: Bool
    
    @State private var takes: [Take] = []
    @State private var selectedTake: Take?
    @State private var recordedTake: Take?
    
    @State private var isPlaying = false
    @State private var showBorder = false
    
    @State private var audioPlayer: AVAudioPlayer?
    
    @ObservedObject var takesViewModel = TakesViewModel.shared
    
    let song: Song
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("Takes")
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                    Spacer()
                    SheetCloseButton(isPresented: $isPresented, padding: 16)
                }
                .padding()
                Divider()
                if takes.isEmpty {
                    FullscreenMessage(imageName: "circle.slash", title: "It doesn't look like you've recorded any takes for this song.", spaceNavbar: true)
                } else {
                    ScrollView {
                        VStack {
                            ForEach(takes.sorted(by: { take1, take2 in
                                return takes.firstIndex(of: take1) ?? 0 > takes.firstIndex(of: take2) ?? 0
                            }), id: \.id) { take in
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation(.bouncy(extraBounce: 0.1)) {
                                            if selectedTake == take {
                                                selectedTake = nil
                                            } else {
                                                selectedTake = take
                                            }
                                        }
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text("Take \((self.takes.firstIndex(of: take) ?? 0) + 1)")
                                                    .font(.title2.weight(.semibold))
                                                    .foregroundColor(showBorder && recordedTake == take ? Color.blue : Color.primary)
                                                Text(take.date.formatted())
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .rotationEffect(selectedTake == take ? Angle(degrees: 90) : Angle(degrees: 0))
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Material.regular)
                                        .foregroundColor(.gray)
                                        .cornerRadius(20, corners: selectedTake == take ? [.topLeft, .topRight] : [.allCorners])
                                        .overlay {
                                            if showBorder && recordedTake == take {
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.blue, lineWidth: 3.5)
                                                    .onAppear {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                            withAnimation(.easeInOut) {
                                                                showBorder = false
                                                            }
                                                        }
                                                    }
                                            }
                                        }
                                        .onChange(of: recordedTake) { take in
                                            withAnimation(.easeInOut) {
                                                showBorder = true
                                            }
                                        }
                                        .contextMenu {
                                            // TODO: Make available to older iOS versions
                                            if #available(iOS 16, *) {
                                                ShareLink(item: take.url, subject: Text("\((takes.firstIndex(of: take) ?? 0) + 1)"))
                                            }
                                            Button(role: .destructive, action: {
                                                do {
                                                    try FileManager.default.removeItem(at: take.url)
                                                    takes.removeAll(where: { $0 == take })
                                                } catch {
                                                    print(error)
                                                }
                                            }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                    if selectedTake == take {
                                        VStack(spacing: 14) {
                                            Divider()
                                                .padding(.horizontal, -16)
                                            HStack {
                                                Button {
                                                    do {
                                                        self.audioPlayer = try AVAudioPlayer(contentsOf: take.url)
                                                        
                                                        if let audioPlayer = audioPlayer {
                                                            if !isPlaying {
                                                                audioPlayer.play()
                                                                isPlaying = true
                                                            } else {
                                                                audioPlayer.pause()
                                                                isPlaying = false
                                                            }
                                                        }
                                                    } catch {
                                                        print(error.localizedDescription)
                                                    }
                                                } label: {
                                                    Image(systemName: isPlaying ? "pause" : "play")
                                                        .padding(10)
                                                        .background(isPlaying ? Color.red : Color.blue)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(6)
                                                }
                                                .onChange(of: audioPlayer?.isPlaying ?? false) { isPlaying in
                                                    if !isPlaying {
                                                        self.isPlaying = false
                                                    }
                                                }
                                            }
                                        }
                                        .padding([.horizontal, .bottom], 14)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Material.regular)
                                        .foregroundColor(.gray)
                                        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                if !takes.isEmpty {
                    Divider()
                    Text("Takes are not synced across devices.")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .onAppear {
                do {
                    self.takes = try takesViewModel.loadRecordedTakes()
                } catch {
                    print("Failed to fetch recorded takes: \(error.localizedDescription)")
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
