//
//  NewTakeView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/17/24.
//

import SwiftUI
import AVFoundation

struct NewTakeView: View {
    @Binding var isDisplayed: Bool
    @Binding var takes: [URL]
    @Binding var recordedTake: URL?
    
    let song: Song
    let audioSession = AVAudioSession.sharedInstance()
    
    @State private var message = ""
    @State private var isRecording = false
    
    @State private var audioRecorder: AVAudioRecorder!
    @State private var elapsedTime: TimeInterval = 0
    @State private var shadow: CGFloat = 0
    @State private var timer: Timer?
    
    @ObservedObject var songViewModel = SongViewModel.shared
    
    func startRecording() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
            
            let baseDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            let audioFilename = baseDir.appendingPathComponent("\(song.id ?? "")_\(UUID().uuidString).wav")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.record()
            
            message = "Recording..."
            isRecording = true
            
            takes.append(audioFilename)
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.shadow = CGFloat.random(in: 0...40)
                self.elapsedTime += 1
            }
        } catch {
            print("Failed to record audio: \(error.localizedDescription)")
        }
    }
    func stopRecording() {
        do {
            try audioSession.setActive(false)
        } catch {
            print(error)
        }
        message = "Saved!"
        audioRecorder.stop()
        isRecording = false
        shadow = 0
        timer?.invalidate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isDisplayed = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                recordedTake = audioRecorder.url
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SheetCloseButton(isPresented: $isDisplayed)
                .frame(maxWidth: .infinity, alignment: .trailing)
            .padding()
            VStack(spacing: 14) {
                Spacer()
                Text(songViewModel.timeFormatted(elapsedTime))
                    .font(.largeTitle.weight(.bold))
                VStack(spacing: 2) {
                    Button(action: {
                        if isRecording {
                            self.stopRecording()
                        } else {
                            self.startRecording()
                        }
                    }) {
                        FAText(iconName: isRecording ? "stop" : "microphone", size: 32)
                            .padding(26)
                            .background(isRecording ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .padding()
                            .animation(nil)
                            .shadow(color: isRecording ? Color.red : Color.blue, radius: shadow).animation(.bouncy(duration: 1))
                    }
                    Text(message)
                        .font(.system(size: 18).weight(.semibold))
                        .foregroundColor(.gray)
                        .opacity(isRecording ? 1 : 0)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    NewTakeView(isDisplayed: .constant(true), takes: .constant([]), recordedTake: .constant(URL(string: "")!), song: Song.song)
}
