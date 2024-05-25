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
    @Published var recordedTake: Take?
    @Published var elapsedTime: TimeInterval = 0
    @Published var audioRecorder: AVAudioRecorder!
    private var timer: Timer?
    
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
    func stopRecording(song: Song, completion: @escaping() -> Void) {
        do {
            try audioSession.setActive(false)
        } catch {
            print(error)
        }
        saveRecordedTake(url: audioRecorder.url, song: song)
        audioRecorder.stop()
        isRecording = false
        timer?.invalidate()
        elapsedTime = 0
        completion()
    }
    func saveAllRecordedTakes() {
        do {
            let baseDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            let fileURL = baseDir.appendingPathComponent("recordedTakes.json")
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(recordedTakes)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save all recorded takes: \(error.localizedDescription)")
        }
    }
    func saveRecordedTake(url: URL, song: Song) {
        let recordedTake = Take(url: url, date: Date(), songId: song.id ?? "", title: nil)
        
        do {
            let baseDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            let fileURL = baseDir.appendingPathComponent("recordedTakes.json")
            
            loadRecordedTakes(forSong: song)
            self.recordedTakes.append(recordedTake)
            self.recordedTake = recordedTake
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(recordedTakes)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save recorded take: \(error.localizedDescription)")
        }
    }
    func loadRecordedTakes(forSong song: Song) {
        let baseDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let fileURL = baseDir.appendingPathComponent("recordedTakes.json")
        
        guard let data = try? Data(contentsOf: fileURL) else {
            self.recordedTakes = []
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let allTakes = try decoder.decode([Take].self, from: data)
            self.recordedTakes = allTakes.filter { $0.songId == song.id }
        } catch {
            print(error.localizedDescription)
        }
    }
    func deleteTake(_ take: Take, song: Song) {
        do {
            try FileManager.default.removeItem(at: take.url)
        } catch {
            print("Failed to delete recorded take: \(error.localizedDescription)")
        }
        
        recordedTakes.removeAll(where: { $0.url == take.url })
        saveAllRecordedTakes()
    }
    func updateTake(_ take: Take?, song: Song, title: String) {
        if let take = take {
            let updatedTake = Take(url: take.url, date: take.date, songId: song.id ?? "", title: title)
            
            loadRecordedTakes(forSong: song)
            
            if let index = recordedTakes.firstIndex(where: { $0.url == take.url }) {
                recordedTakes[index] = updatedTake
            } else {
                print("Take not found, cannot update.")
            }
            
            saveAllRecordedTakes()
        } else {
            print("Take is nil")
        }
    }
    func deleteAllTakes(forSong song: Song) {
        loadRecordedTakes(forSong: song)
        recordedTakes.removeAll()
        saveAllRecordedTakes()
    }
}
