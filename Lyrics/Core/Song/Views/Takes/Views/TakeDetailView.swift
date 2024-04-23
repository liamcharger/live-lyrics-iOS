//
//  TakeDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/22/24.
//

import SwiftUI
import AVFoundation

struct TakeDetailView: View {
    @Binding var isPresented: Bool
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var isPlayingOnPlayer = false
    @State private var showTakeEditView = false
    @State private var showDeleteConfirmation = false
    @State private var playbackTime: TimeInterval = 0
    @State private var timer: Timer?
    
    @State private var title: String = ""
    
    let take: Take
    let song: Song
    
    func togglePlayback() {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
            } else {
                player.play()
            }
            withAnimation {
                isPlayingOnPlayer.toggle()
                isPlaying.toggle()
            }
        }
    }
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let player = audioPlayer {
                withAnimation {
                    playbackTime = player.currentTime
                }
            }
        }
    }
    func stopTimer() {
        timer?.invalidate()
    }
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            audioPlayer?.pause()
        } else {
            audioPlayer?.currentTime = playbackTime
            if isPlayingOnPlayer {
                audioPlayer?.play()
                isPlaying = true
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SheetCloseButton(isPresented: $isPresented, padding: 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
            VStack(spacing: 22) {
                Spacer()
//                ZStack {
//                    if isPlaying {
//                        AnimatedCircleView()
//                    }
//
//                }
                VStack(spacing: 6) {
                    Text(title.uppercased())
                        .font(.system(size: 18).weight(.semibold))
                        .foregroundColor(.gray)
                    Text(formatTime(playbackTime))
                        .font(.system(size: 42, design: .rounded).weight(.bold))
                }
                Spacer()
                HStack(spacing: 10) {
                    Button(action: togglePlayback) {
                        FAText(iconName: isPlaying ? "stop" : "play", size: 18)
                            .offset(x: isPlaying ? 0 : 2)
                            .padding()
                            .background(isPlaying ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .onChange(of: audioPlayer?.isPlaying ?? false) { isPlaying in
                        if !isPlaying {
                            self.isPlaying = false
                        }
                    }
                    VStack(spacing: 6) {
                        Slider(value: $playbackTime, in: 0...(audioPlayer?.duration ?? 0), onEditingChanged: sliderEditingChanged)
                        HStack {
                            Text(formatTime(playbackTime))
                            Spacer()
                            Text(formatTime(audioPlayer?.duration ?? 0))
                        }
                    }
                }
                HStack(spacing: 16) {
                    Button {
                        showTakeEditView = true
                    } label: {
                        HStack(spacing: 7) {
                            FAText(iconName: "pen", size: 18)
                            Text("Rename")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Material.regular)
                        .foregroundColor(.blue)
                        .cornerRadius(15)
                    }
                    .sheet(isPresented: $showTakeEditView) {
                        TakeEditView(isDisplayed: $showTakeEditView, titleToUpdate: $title, song: song, take: take)
                    }
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 7) {
                            FAText(iconName: "trash-can", size: 18)
                            Text("Delete")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                }
            }
            .padding()
        }
        .confirmationDialog("Delete Take", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                TakesViewModel.shared.deleteTake(take, song: song)
                isPresented = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
             Text("Are you sure you want to delete '\(title)'?")
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startTimer()
            } else {
                stopTimer()
            }
        }
        .onAppear {
            self.title = take.title ?? "Take"
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: take.url)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error initializing AVAudioPlayer: \(error.localizedDescription)")
                return
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
}

#Preview {
    TakeDetailView(isPresented: .constant(true), take: Take(url: URL(string: "")!, date: Date(), songId: "", title: "Test"), song: Song.song)
}
