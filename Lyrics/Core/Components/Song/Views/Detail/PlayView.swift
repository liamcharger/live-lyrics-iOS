//
//  SongDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import SwiftUI
import BottomSheet
import UIKit
import AVFoundation
import TipKit

enum BeatStyle {
    case medium
    case heavy
}

struct PlayView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var bpm: Int
    @Binding var bpb: Int
    @Binding var performanceMode: Bool
    
    @State var song: Song
    
    @State private var currentSongSelection = 0
    @State private var currentTime: Double = 0
    @State private var autoscrollTimerTime: Double = 0
    
    @State private var selectedTool = ""
    
    @State private var timestamps = [String]()
    
    @State private var currentLineIndex: Int = 0
    @State private var scrollTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var syncLyricTimer: Timer?
    @State private var beatCounter: Int = 0
    @State private var pressedIndexId: Int = 0
    @State private var countdown: Int = 4
    
    @State private var isPlayingMetronome = false
    @State private var isPulsing = false
    @State private var isScrolling = false
    @State private var isUserScrolling = false
    @State private var isScrollingProgrammatically = true
    @State private var isPressed = false
    @State private var isShowingCountdown = false
    @State private var isSyncing = false
    @State private var isShowingSyncModeAlert = false
    
    @State private var proxy: ScrollViewProxy?
    
    @State private var clickAudioPlayer: AVAudioPlayer?
    @State private var accentAudioPlayer: AVAudioPlayer?
    
    @State private var metronomeTimer: DispatchSourceTimer?
    
    @AppStorage("hasUsedSyncMode") var hasUsedSyncMode = false
    
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var viewModel = AuthViewModel.shared
    
    var songs: [Song]?
    
    let size: Int
    let weight: Font.Weight
    let lineSpacing: Double
    let alignment: TextAlignment
    
    let metronomeDispatchQueue = DispatchQueue(label: "com.chargertech.Lyrics.metronome", attributes: .concurrent)
    
    var lines: [String] {
        return song.lyrics.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    func swipeLeft() {
        currentSongSelection += 1
        if currentSongSelection >= songs!.count {
            currentSongSelection = 0
        }
        if let songs = songs {
            self.song = songs[currentSongSelection]
        }
        self.bpb = song.bpb ?? 4
        self.bpm = song.bpm ?? 120
        self.performanceMode = song.performanceMode ?? true
        if isScrolling {
            pauseAutoscroll()
        }
    }
    func swipeRight() {
        currentSongSelection -= 1
        if currentSongSelection < 0 {
            currentSongSelection = songs!.count - 1
        }
        if let songs = songs {
            self.song = songs[currentSongSelection]
        }
        self.bpb = song.bpb ?? 4
        self.bpm = song.bpm ?? 120
        self.performanceMode = song.performanceMode ?? true
        if isScrolling {
            pauseAutoscroll()
        }
    }
    func startAutoscroll(scrollViewProxy: ScrollViewProxy) {
        guard !timestamps.isEmpty else { return }
        
        isScrolling = true
        isScrollingProgrammatically = true
        
        if autoscrollTimerTime == 0 {
            startCountdown()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            stopCountdown()
            
            scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.autoscrollTimerTime += 0.5
                
                if currentLineIndex < timestamps.count {
                    let components = timestamps[currentLineIndex].split(separator: "_")
                    if components.count == 2,
                       let lineIndex = Int(components[0]),
                       let targetTime = Double(components[1]),
                       autoscrollTimerTime >= targetTime {
                        self.scrollTo(lineIndex + 1)
                    }
                } else {
                    self.scrollTimer?.invalidate()
                    self.scrollTimer = nil
                    self.isScrolling = false
                    self.autoscrollTimerTime = 0
                    self.scrollTo(0)
                }
            }
        }
    }
    func skipToLine(_ index: Int) {
        let components = timestamps[index].split(separator: "_")
        
        if components.count == 2,
           let lineIndex = Int(components[0]),
           let targetTime = Double(components[1]) {
            print(autoscrollTimerTime, targetTime)
            print(targetTime - autoscrollTimerTime)
            
            // FIXME: when skipping, the selected line is briefly highlighted before being switched to the next
            
            self.autoscrollTimerTime += targetTime - autoscrollTimerTime
            self.scrollTo(lineIndex)
        }
    }
    func scrollTo(_ index: Int) {
        DispatchQueue.main.async {
            self.isScrollingProgrammatically = true
            
            if let scrollViewProxy = proxy {
                withAnimation(.smooth) {
                    scrollViewProxy.scrollTo(index, anchor: self.performanceMode ? .center : .top)
                    
                    currentLineIndex = index
                }
            }
        }
    }
    func pauseAutoscroll() {
        isScrolling = false
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    func startCountdown() {
        countdown = 3
        withAnimation(.smooth) {
            isShowingCountdown = true
        }
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            }
        }
    }
    func stopCountdown() {
        withAnimation(.smooth) {
            isShowingCountdown = false
        }
        
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    func recordTimestamp() {
        self.isScrollingProgrammatically = true
        
        guard currentLineIndex < lines.count else { return }
        
        let timestamp = String(currentTime)
        let timestampString = "\(currentLineIndex)_\(timestamp)"
        
        timestamps.append(timestampString)
        
        if currentLineIndex < lines.count - 1 {
            scrollTo(currentLineIndex + 1)
        } else {
            isSyncing = false
            scrollTo(0)
            syncLyricTimer?.invalidate()
            syncLyricTimer = nil
            songViewModel.updateAutoscrollTimestamps(for: song, with: timestamps)
        }
    }
    func startSyncing() {
        isSyncing = true
        isScrollingProgrammatically = true
        scrollTo(0)
        
        startCountdown()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            stopCountdown()
            syncLyricTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                currentTime += 0.5
            }
        }
    }
    func startMetronome() {
        stopMetronome()
        
        isPlayingMetronome = true
        beatCounter = 0
        
        let interval = 60.0 / Double(bpm)
        
        metronomeTimer = DispatchSource.makeTimerSource(queue: metronomeDispatchQueue)
        
        metronomeTimer?.setEventHandler {
            DispatchQueue.main.async {
                if !isPlayingMetronome {
                    return
                }
                
                self.beatCounter += 1
                
                let shouldPlayHeavyBeat = self.beatCounter == 1 || (self.beatCounter - 1) % self.bpb == 0
                
                if shouldPlayHeavyBeat {
                    self.playBeat(style: .heavy)
                } else {
                    self.playBeat(style: .medium)
                }
                
                self.isPulsing.toggle()
            }
        }
        
        DispatchQueue.main.async {
            if let metronomeTimer = metronomeTimer {
                metronomeTimer.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(10))
            }
        }
        metronomeTimer?.activate()
    }
    func stopMetronome() {
        isPlayingMetronome = false
        isPulsing = false
        beatCounter = 0
        metronomeTimer?.cancel()
        metronomeTimer = nil
    }
    func loadSounds() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
        
        guard let clickUrl = Bundle.main.url(forResource: "lo_click", withExtension: "wav") else {
            fatalError("click sound not found.")
        }
        
        guard let accentUrl = Bundle.main.url(forResource: "hi_click", withExtension: "wav") else {
            fatalError("accent sound not found.")
        }
        
        do {
            clickAudioPlayer = try AVAudioPlayer(contentsOf: clickUrl)
            clickAudioPlayer?.prepareToPlay()
            
            accentAudioPlayer = try AVAudioPlayer(contentsOf: accentUrl)
            accentAudioPlayer?.prepareToPlay()
        } catch {
            fatalError("unable to load click sound: \(error)")
        }
    }
    func playBeat(style: BeatStyle) {
        if let user = viewModel.currentUser, let metronomeStyle = user.metronomeStyle {
            switch style {
            case .medium:
                if metronomeStyle.contains("Vibrations") {
                    hapticByStyle(.medium)
                }
                if metronomeStyle.contains("Audio") {
                    clickAudioPlayer?.play()
                }
            case .heavy:
                if metronomeStyle.contains("Vibrations") {
                    hapticByStyle(.heavy)
                }
                if metronomeStyle.contains("Audio") {
                    accentAudioPlayer?.play()
                }
            }
        }
    }
    func getBlur(for index: Int) -> CGFloat {
        if performanceMode {
            if isScrollingProgrammatically && !isUserScrolling {
                let distance = abs(currentLineIndex - index)
                
                if distance == 0 {
                    return 0
                } else if distance == 1 {
                    return 4
                } else if distance == 2 {
                    return 8
                } else {
                    return 11
                }
            } else {
                return 0
            }
        } else {
            if currentLineIndex != index && (isScrollingProgrammatically && !isUserScrolling) {
                return 1.8
            } else {
                return 0
            }
        }
    }
    func readOnly() -> Bool {
        return (song.readOnly ?? false) || (mainViewModel.selectedFolder?.readOnly ?? false)
    }
    
    init(song: Song, size: Int, weight: Font.Weight, lineSpacing: Double, alignment: TextAlignment, bpm: Binding<Int>, bpb: Binding<Int>, performanceMode: Binding<Bool>, songs: [Song]?) {
        self.songs = songs
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.weight = weight
        self.size = size
        self.timestamps = song.autoscrollTimestamps ?? []
        
        self._song = State(initialValue: song)
        self._currentSongSelection = State(initialValue: song.order ?? 0)
        self._bpb = bpb
        self._bpm = bpm
        self._performanceMode = performanceMode
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    VStack(spacing: 0) {
                        HStack {
                            Text(song.title)
                                .font(.title2.weight(.bold))
                                .lineLimit(1).truncationMode(.tail)
                            Spacer()
                            if let key = song.key, key != "" {
                                Text("Key: " + key)
                                    .foregroundColor(Color.gray)
                                    .padding(.trailing, 6)
                            }
                            if !isSyncing {
                                Button {
                                    if selectedTool == "metronome" {
                                        selectedTool = ""
                                    } else {
                                        selectedTool = "metronome"
                                    }
                                } label: {
                                    Image(systemName: "metronome")
                                        .imageScale(.medium)
                                        .padding(11)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(selectedTool == "metronome" ? .white : .primary)
                                        .background(selectedTool == "metronome" ? .blue : .materialRegularGray)
                                        .clipShape(Circle())
                                }
                            }
                            CloseButton {
                                pauseAutoscroll()
                                stopMetronome()
                                dismiss()
                            }
                        }
                        .padding(hasHomeButton() ? .top : [])
                        .padding([.horizontal, .bottom])
                        Divider()
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: performanceMode ? 25 : lineSpacing) {
                                    ForEach(lines.indices, id: \.self) { index in
                                        let line = lines[index]
                                        
                                        Group {
                                            if !performanceMode {
                                                Button {
                                                    if isScrolling {
                                                        skipToLine(index)
                                                    } else {
                                                        scrollTo(index)
                                                    }
                                                } label: {
                                                    Text(line)
                                                        .foregroundStyle((currentLineIndex == index && isScrolling) ? Color.blue : .primary)
                                                        .font(.system(size: CGFloat(size), weight: weight))
                                                        .id(index)
                                                        .animation(.spring(dampingFraction: 1.0), value: currentLineIndex)
                                                }
                                                .disabled(isSyncing)
                                            } else {
                                                Button {
                                                    if isScrolling {
                                                        skipToLine(index)
                                                    } else {
                                                        scrollTo(index)
                                                    }
                                                } label: {
                                                    Text(line)
                                                        .font(.system(size: 42, weight: .bold, design: .rounded))
                                                        .foregroundColor(.primary)
                                                        .padding(5)
                                                        .scaleEffect((isPressed && pressedIndexId == index) ? 0.85 : 1)
                                                        .blur(radius: (isPressed && pressedIndexId == index) ? 0 : getBlur(for: index))
                                                        .animation(.spring(dampingFraction: 1.0), value: currentLineIndex)
                                                        .id(index)
                                                }
                                                .disabled(isSyncing)
                                                .buttonStyle(ScaleButtonStyle(isPressed: $isPressed, pressedIndexId: $pressedIndexId, index: index))
                                                .shadow(color: (currentLineIndex == index && isScrolling && !isPressed) ? Color.blue : Color.clear, radius: 10, y: 8)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding()
                            }
                            .scrollStatusByIntrospect(isScrolling: $isUserScrolling, isScrollingProgrammatically: $isScrollingProgrammatically)
                            .onAppear {
                                self.proxy = proxy
                            }
                        }
                    }
                }
                if !selectedTool.isEmpty {
                    Divider()
                    Group {
                        switch selectedTool {
                        case "metronome":
                            VStack(alignment: .leading, spacing: 6) {
                                Text("METRONOME")
                                    .font(.caption.weight(.semibold))
                                HStack {
                                    Menu {
                                        Stepper("\(bpm) Beats Per Minute", value: $bpm, in: 25...260)
                                    } label: {
                                        Text("\(bpm) BPM")
                                            .padding(10)
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                            .background(Material.regular)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .onChange(of: bpm) { bpm in
                                        stopMetronome()
                                        songViewModel.updateBpm(for: song, with: bpm)
                                    }
                                    .disabled(readOnly())
                                    Menu {
                                        ForEach(1...8, id: \.self) { bpb in
                                            Button {
                                                self.bpb = bpb
                                            } label: {
                                                Label("\(bpb)", systemImage: self.bpb == bpb ? "checkmark" : "")
                                            }
                                        }
                                    } label: {
                                        Text("\(bpb) BPB")
                                            .padding(10)
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                            .background(Material.regular)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .onChange(of: bpb) { bpb in
                                        songViewModel.updateBpb(for: song, with: bpb)
                                    }
                                    .disabled(readOnly())
                                    Spacer()
                                    if isPulsing {
                                        Circle()
                                            .frame(width: 12, height: 12)
                                            .foregroundColor(.primary)
                                    }
                                    Button {
                                        if isPlayingMetronome {
                                            stopMetronome()
                                        } else {
                                            loadSounds()
                                            startMetronome()
                                        }
                                    } label: {
                                        FAText(iconName: isPlayingMetronome ? "pause" : "play", size: 18)
                                            .padding()
                                            .padding(.trailing, isPlayingMetronome ? 0 : -2)
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.white)
                                            .background(isPlayingMetronome ? .red : .blue)
                                            .clipShape(Circle())
                                    }
                                    Button {
                                        isPlayingMetronome = false
                                        selectedTool = ""
                                    } label: {
                                        Image(systemName: "xmark")
                                            .padding(15)
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                            .background(Material.regular)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        default:
                            EmptyView()
                        }
                    }
                    .padding(12)
                }
                Divider()
                HStack {
                    if songs != nil && !isSyncing {
                        Button(action: {
                            DispatchQueue.main.async {
                                swipeRight()
                                hapticByStyle(.medium)
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .imageScale(.medium)
                                .padding()
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                                .background(Material.regular)
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                    if lines.count > 1 {
                        HStack {
                            Button(action: {
                                if !timestamps.isEmpty && !isSyncing {
                                    if let proxy = proxy {
                                        if isScrolling {
                                            pauseAutoscroll()
                                        } else {
                                            startAutoscroll(scrollViewProxy: proxy)
                                        }
                                    }
                                } else {
                                    if !isSyncing {
                                        if hasUsedSyncMode {
                                            startSyncing()
                                        } else {
                                            isShowingSyncModeAlert = true
                                        }
                                    } else {
                                        recordTimestamp()
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: isSyncing ? "chevron.down" : (isScrolling ? "pause" : "play"))
                                    if isSyncing {
                                        Text("Next Line")
                                    } else {
                                        if timestamps.isEmpty {
                                            // The user isn't in sync mode and hasn't synced the song yet
                                            Text("Sync Lyrics")
                                        } else {
                                            Text(isScrolling ? "Pause" : "Autoscroll")
                                        }
                                    }
                                }
                                .imageScale(.medium)
                                .padding()
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)
                                .background(isScrolling ? .red : .blue)
                                .clipShape(Capsule())
                            }
                            if !readOnly() && !isSyncing {
                                Menu {
                                    if !timestamps.isEmpty {
                                        Button {
                                            if isScrolling {
                                                pauseAutoscroll()
                                                scrollTo(0)
                                            } else {
                                                startSyncing()
                                            }
                                        } label: {
                                            Label("Re-sync Lyrics", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90")
                                        }
                                    }
                                    Button {
                                        performanceMode.toggle()
                                    } label: {
                                        Label("Performance Mode", systemImage: performanceMode ? "checkmark" : "")
                                    }
                                } label: {
                                    FAText(iconName: "gear", size: 20)
                                        .imageScale(.medium)
                                        .padding()
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.primary)
                                        .background(Material.regular)
                                        .clipShape(Circle())
                                }
                                .onChange(of: performanceMode) { performanceMode in
                                    songViewModel.updatePerformanceMode(for: song, with: performanceMode)
                                }
                            }
                        }
                    }
                    Spacer()
                    if songs != nil && !isSyncing {
                        Button(action: {
                            DispatchQueue.main.async {
                                swipeLeft()
                                hapticByStyle(.medium)
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .imageScale(.medium)
                                .padding()
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                                .background(Material.regular)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding([.horizontal, .top])
                .padding(hasHomeButton() ? .bottom : [])
            }
            .blur(radius: isShowingCountdown ? 35 : 0)
            .disabled(isShowingCountdown)
            if isShowingCountdown {
                Text("\(countdown)")
                    .font(.system(size: 80).weight(.bold))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $isShowingSyncModeAlert) {
            Alert(title: Text("To sync your lyrics, use the button below to scroll the lyrics at the desired time."), dismissButton: .cancel(Text("OK"), action: {
                isShowingSyncModeAlert = false
                hasUsedSyncMode = true
                startSyncing()
            }))
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    @Binding var pressedIndexId: Int
    let index: Int
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { isPressed in
                withAnimation(.smooth) {
                    self.isPressed = isPressed
                    self.pressedIndexId = index
                }
            }
    }
}

#Preview {
    PlayView(song: Song(id: "idddd", uid: "uiddd", timestamp: Date(), title: "Test Song", lyrics: "" /* TODO: verify that we can remove all the extra view params now that the song param is updated from an event listener in SongDetailView */, order: 0, size: 18, key: "the key of K", notes: nil, weight: nil, alignment: nil, lineSpacing: nil, artist: nil, bpm: nil, bpb: nil, pinned: nil, performanceMode: nil, tags: nil, demoAttachments: nil, bandId: nil, joinedUsers: nil, variations: nil, readOnly: nil), size: 18, weight: .regular, lineSpacing: 1, alignment: .leading, bpm: .constant(120), bpb: .constant(4), performanceMode: .constant(true), songs: [Song.song])
}
