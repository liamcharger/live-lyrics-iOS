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
    
    @State private var takes: [URL] = []
    @State private var selectedTake: URL?
    @State private var recordedTake: URL?
    
    @State private var showNewTakeSheet = false
    @State private var isPlaying = false
    @State private var showBorder = false
    
    @State var avPlayer: AVPlayer?
    
    let song: Song
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("Takes")
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                    Spacer()
                    Button {
                        showNewTakeSheet.toggle()
                    } label: {
                        FAText(iconName: "pen-to-square", size: 20)
                            .modifier(NavBarRowViewModifier())
                    }
                    .sheet(isPresented: $showNewTakeSheet) {
                        NewTakeView(isDisplayed: $showNewTakeSheet, takes: $takes, recordedTake: $recordedTake, song: song)
                    }
                    SheetCloseButton(isPresented: $isPresented, padding: 16)
                }
                .padding()
                Divider()
                if takes.isEmpty {
                    FullscreenMessage(imageName: "circle.slash", title: "It doesn't look like you've recorded any takes for this song.", spaceNavbar: true)
                } else {
                    ScrollView {
                        VStack {
                            ForEach(takes.sorted(by: { url1, url2 in
                                return takes.firstIndex(of: url1) ?? 0 > takes.firstIndex(of: url2) ?? 0
                            }), id: \.self) { take in
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
                                                Text("04/17/2024")
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
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
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
                                                ShareLink(item: take, subject: Text("\((takes.firstIndex(of: take) ?? 0) + 1)"))
                                            }
                                            Button(role: .destructive, action: {
                                                do {
                                                    try FileManager.default.removeItem(at: take)
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
                                                    self.avPlayer = AVPlayer(url: take)
                                                    
                                                    if let avPlayer = avPlayer {
                                                        if !isPlaying {
                                                            avPlayer.play()
                                                            isPlaying = true
                                                        } else {
                                                            avPlayer.pause()
                                                            isPlaying = false
                                                        }
                                                    }
                                                } label: {
                                                    Image(systemName: isPlaying ? "pause" : "play")
                                                        .padding(10)
                                                        .background(isPlaying ? Color.red : Color.blue)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(6)
                                                }
                                                Spacer()
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
            }
            .onAppear {
                self.fetchRecordedTakes()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    func fetchRecordedTakes() {
        let baseDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        do {
            let recordingURLs = try FileManager.default.contentsOfDirectory(at: baseDir, includingPropertiesForKeys: nil, options: [])
            takes = recordingURLs.filter { $0.lastPathComponent.contains("\(song.id ?? "")") }
        } catch {
            print("Failed to fetch recorded takes: \(error.localizedDescription)")
        }
    }
}
