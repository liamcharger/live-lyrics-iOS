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
    @State private var currentSyncingTime: Double = 0
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
    @State private var isLyricPressed = false
    @State private var isShowingCountdown = false
    @State private var isSyncing = false
    @State private var isPaused = false
    
    @State private var proxy: ScrollViewProxy?
    
    @State private var clickAudioPlayer: AVAudioPlayer?
    @State private var accentAudioPlayer: AVAudioPlayer?
    
    @State private var metronomeTimer: DispatchSourceTimer?
    
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
    func startAutoscroll() {
        // FIXME: noted bugs
        /// - When toggling performance view after pausing the autoscroll, the timer continues and scrolls
        /// - Lines should be highlighted even when paused when not in performance view
        /// - LInes not being highlighted when syncing when not in performance view
        ///  - Chevron buttons switch to unpredicted selections
        
        guard !timestamps.isEmpty else { return }
        
        isScrolling = true
        isScrollingProgrammatically = true
        isPaused = false
        
        if autoscrollTimerTime == 0 {
            startCountdown()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (autoscrollTimerTime == 0 ? 3 : 0)) {
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
        func scrollToTop() {
            self.autoscrollTimerTime = 0
            self.scrollTo(0)
        }
        
        // The user tapped the top line, so scroll there
        guard index != 0 else {
            scrollToTop()
            return
        }
        // Make sure there is a line before the current one
        guard let previousIndex = Double(timestamps[index - 1].split(separator: "_").last ?? "") else {
            scrollToTop()
            return
        }
        
        let components = timestamps[index].split(separator: "_")
        if let lineIndex = Int(components[0]) {
            // Assign the time before the current index
            self.autoscrollTimerTime = previousIndex
            // Scroll to the user requested line
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
        isPaused = true
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
        isScrollingProgrammatically = true
        
        guard currentLineIndex < lines.count else { return }
        
        let timestamp = String(currentSyncingTime)
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
                currentSyncingTime += 0.5
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
            print("Low click sound not found.")
            return
        }
        
        guard let accentUrl = Bundle.main.url(forResource: "hi_click", withExtension: "wav") else {
            print("Hi click sound not found")
            return
        }
        
        do {
            clickAudioPlayer = try AVAudioPlayer(contentsOf: clickUrl)
            clickAudioPlayer?.prepareToPlay()
            
            accentAudioPlayer = try AVAudioPlayer(contentsOf: accentUrl)
            accentAudioPlayer?.prepareToPlay()
        } catch {
            print("unable to load click sound: \(error)")
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
                                                Text(line)
                                                    .foregroundStyle((currentLineIndex == index && isScrolling) ? Color.blue : .primary)
                                                    .font(.system(size: CGFloat(size), weight: weight))
                                                    .id(index)
                                                    .animation(.spring(dampingFraction: 1.0), value: currentLineIndex)
                                                    .onTapGesture {
                                                        if !isSyncing {
                                                            if isScrolling {
                                                                skipToLine(index)
                                                            } else {
                                                                scrollTo(index)
                                                            }
                                                        }
                                                    }
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
                                                        .scaleEffect((isLyricPressed && pressedIndexId == index) ? 0.85 : 1)
                                                        .blur(radius: (isLyricPressed && pressedIndexId == index) ? 0 : getBlur(for: index))
                                                        .animation(.spring(dampingFraction: 1.0), value: currentLineIndex)
                                                        .id(index)
                                                }
                                                .disabled(isSyncing)
                                                .buttonStyle(ScaleButtonStyle(isLyricPressed: $isLyricPressed, pressedIndexId: $pressedIndexId, index: index))
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
                } else if let lastEdited = song.lastLyricsEdited, let lastSynced = song.lastSynced, lastEdited > lastSynced {
                    Divider()
                    // TODO: create component
                    HStack(spacing: 9) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 26).weight(.semibold))
                            .foregroundStyle(Color.orange)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Your lyrics were updated after the last sync.")
                                .font(.system(size: 18.5).weight(.semibold))
                            Text("Scrolling may be timed incorrectly.")
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.orange, lineWidth: 2)
                    }
                    .padding(8)
                }
                Divider()
                HStack {
                    if songs != nil && !isSyncing && !isScrolling && !isPaused {
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
                    } else if isSyncing || isPaused || isScrolling {
                        HStack(spacing: 7) {
                            Text({
                                let time = isSyncing ? currentSyncingTime : autoscrollTimerTime
                                let minutes = Int(time) / 60
                                let seconds = Int(time) % 60
                                
                                return String(format: "%02d:%02d", minutes, seconds)
                            }())
                            .font(.system(size: 21).weight(.semibold))
                            if lines.count > 1 && isSyncing {
                                Text("•")
                                    .font(.system(size: 19).weight(.medium))
                                Text("\(Int((Double(currentLineIndex) / Double(lines.count)) * 100))%")
                                    .font(.system(size: 21).weight(.semibold))
                                    .transition(.identity)
                            }
                        }
                    }
                    Spacer()
                    if lines.count > 1 {
                        HStack {
                            // TODO: "cancel sync" button
                            Button(action: {
                                if !timestamps.isEmpty && !isSyncing {
                                    if isScrolling {
                                        pauseAutoscroll()
                                    } else {
                                        startAutoscroll()
                                    }
                                } else {
                                    if !isSyncing {
                                        startSyncing()
                                    } else {
                                        recordTimestamp()
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: isSyncing ? "chevron.down" : (isScrolling ? "pause" : isPaused ? "play" : "playpause"))
                                    if isSyncing {
                                        Text("Next Line")
                                    } else {
                                        if timestamps.isEmpty {
                                            // The user isn't in sync mode and hasn't synced the song yet
                                            Text("Sync Lyrics")
                                        } else {
                                            Text(isScrolling ? "Pause" : isPaused ? "Play" : "Autoscroll")
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
                            .transition(.slide)
                            if !readOnly() && !isSyncing && !isScrolling && !isPaused {
                                Menu {
                                    if !timestamps.isEmpty {
                                        Button {
                                            if isScrolling {
                                                pauseAutoscroll()
                                                scrollTo(0)
                                            }
                                            startSyncing()
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
                        .transition(.slide)
                    }
                    if songs != nil && !isSyncing && !isScrolling && !isPaused {
                        Spacer()
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
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    @Binding var isLyricPressed: Bool
    @Binding var pressedIndexId: Int
    let index: Int
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { isPressed in
                withAnimation(.smooth) {
                    self.isLyricPressed = isPressed
                    self.pressedIndexId = index
                }
            }
    }
}

#Preview {
    PlayView(song: Song(id: "idddd", uid: "uiddd", timestamp: Date(), lastSynced: Date(), lastEdited: Date(), lastLyricsEdited: Date(), title: "Test Song", lyrics: "" /* TODO: verify that we can remove all the extra view params now that the song param is updated from an event listener in SongDetailView */, order: 0, key: "the key of K", notes: nil, size: 18, weight: nil, alignment: nil, lineSpacing: nil, artist: nil, bpm: nil, bpb: nil, pinned: nil, performanceMode: nil, tags: nil, demoAttachments: nil, bandId: nil, autoscrollTimestamps: nil, joinedUsers: nil, variations: nil, readOnly: nil), size: 18, weight: .regular, lineSpacing: 1, alignment: .leading, bpm: .constant(120), bpb: .constant(4), performanceMode: .constant(true), songs: [])
}
