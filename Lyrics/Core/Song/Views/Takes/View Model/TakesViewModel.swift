//
//  TakesViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 4/22/24.
//

import Foundation
import AVFoundation

class TakesViewModel: ObservableObject {
    static let shared = TakesViewModel()
    let audioSession = AVAudioSession.sharedInstance()
    
    @Published var isRecording = false
    @Published var recordedTakes: [Take] = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var audioRecorder: AVAudioRecorder!
    private var timer: Timer?
    
    init() {
        do {
            self.recordedTakes = try loadRecordedTakes()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func startRecording(song: Song) {
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
            
            isRecording = true
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.elapsedTime += 1
            }
        } catch {
            print("Failed to record audio: \(error.localizedDescription)")
        }
    }
    func stopRecording(completion: @escaping() -> Void) {
        do {
            try audioSession.setActive(false)
        } catch {
            print(error)
        }
        saveRecordedTake(url: audioRecorder.url)
        audioRecorder.stop()
        isRecording = false
        timer?.invalidate()
        completion()
    }
    func saveRecordedTake(url: URL) {
        let recordedTake = Take(url: url, date: Date())
        
        do {
            let baseDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            let fileURL = baseDir.appendingPathComponent("recordedTakes.json")
            
            var recordedTakes = try loadRecordedTakes()
            recordedTakes.append(recordedTake)
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(recordedTakes)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save recorded take: \(error.localizedDescription)")
        }
    }
    func loadRecordedTakes() throws -> [Take] {
        let baseDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let fileURL = baseDir.appendingPathComponent("recordedTakes.json")
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Take].self, from: data)
    }
}
