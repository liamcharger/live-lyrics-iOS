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
    @Binding var dismiss: Bool
    @Binding var bpm: Int
    @Binding var bpb: Int
    @Binding var performanceMode: Bool
    
    @State var song: Song
    
    @State private var currentIndex = 0
    @State private var offset: CGFloat = 0
    
    @State var lyrics = ""
    @State var lyricsCollection = [""]
    @State var timestamps = [String]()
    @State var title = ""
    @State var key = ""
    @State var selectedTool = ""
    
    @State var scrollPosition: Int = 0
    @State var currentLineIndex: Int = 0
    @State var scrollTimer: Timer?
    @State var linesHeight: CGFloat = 0.0
    @State var beatCounter: Int = 0
    @State var pressedIndexId: Int = 0
    @State var countdown: Int = 3
    @State var currentTime: Double = 0
    @State var autoscrollTimerTime: Double = 0
    
    @State var isPlayingMetronome = false
    @State var isPulsing = false
    @State var isHeavyImpactPlaying = false
    @State var isScrolling = false
    @State var isUserScrolling = false
    @State var isScrollingProgrammatically = true
    @State var isPressed = false
    @State var isSyncing = false
    @State var showSyncControls = false
    @State var showCountdown = false
    
    @State var proxy: ScrollViewProxy?
    
    @State var countdownTimer: Timer?
    @State var syncLyricTimer: Timer?
    
    @State var clickAudioPlayer: AVAudioPlayer?
    @State var accentAudioPlayer: AVAudioPlayer?
    
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @EnvironmentObject var viewModel: AuthViewModel
    
    @Environment(\.presentationMode) var presMode
    
    var songs: [Song]?
    @State var metronomeTimer: DispatchSourceTimer?
    
    let size: Int
    let weight: Font.Weight
    let design: Font.Design
    let lineSpacing: Double
    let alignment: TextAlignment
    
    let metronomeDispatchQueue = DispatchQueue(label: "com.chargertech.Lyrics.metronome", attributes: .concurrent)
    
    @Binding var duration: String
    
    var lines: [String] {
        return lyrics.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    func swipeLeft() {
        currentIndex += 1
        if currentIndex >= songs!.count {
            currentIndex = 0
        }
        if let songs = songs {
            self.song = songs[currentIndex]
        }
        self.lyrics = self.song.lyrics
        self.title = song.title
        self.key = song.key ?? "Not Set"
        self.duration = song.duration ?? "2:00"
        self.bpb = song.bpb ?? 4
        self.bpm = song.bpm ?? 120
        self.performanceMode = song.performanceMode ?? true
        if let proxy = proxy, isScrolling {
            stopAutoscroll(scrollViewProxy: proxy)
        }
    }
    func swipeRight() {
        currentIndex -= 1
        if currentIndex < 0 {
            currentIndex = songs!.count - 1
        }
        if let songs = songs {
            self.song = songs[currentIndex]
        }
        self.lyrics = self.song.lyrics
        self.title = song.title
        self.key = song.key ?? "Not Set"
        self.duration = song.duration ?? "2:00"
        self.bpb = song.bpb ?? 4
        self.bpm = song.bpm ?? 120
        self.performanceMode = song.performanceMode ?? true
        if let proxy = proxy, isScrolling {
            stopAutoscroll(scrollViewProxy: proxy)
        }
    }
    func durationStringToSeconds(_ duration: String) -> Double {
        let components = duration.split(separator: ":")
        if components.count == 2,
           let minutes = Double(components[0]),
           let seconds = Double(components[1]) {
            print("Minutes: \(minutes), Seconds: \(seconds)")
            return (minutes * 60) + seconds
        }
        return 0
    }
//    func startAutoscroll(scrollViewProxy: ScrollViewProxy) {
//        isScrolling = true
//        isScrollingProgrammatically = true
//        
//        var duration = "2:00"
//        if !self.duration.isEmpty || self.duration != "" {
//            duration = self.duration
//        }
//        
//        scrollTimer = Timer.scheduledTimer(withTimeInterval: durationStringToSeconds(duration) / Double(lines.count), repeats: true) { _ in
//            withAnimation {
//                isScrollingProgrammatically = true
//                
//                if currentLineIndex >= lines.count {
//                    currentLineIndex = 0
//                    scrollTo(0)
//                    scrollTimer?.invalidate()
//                    isScrolling = false
//                } else {
//                    scrollPosition = currentLineIndex + 1
//                    scrollViewProxy.scrollTo(Int(scrollPosition), anchor: performanceMode ? .center : .top)
//                    currentLineIndex += 1
//                }
//            }
//        }
//    }
    func startAutoscroll(scrollViewProxy: ScrollViewProxy) {
        guard !timestamps.isEmpty else { return }
        
        isScrolling = true
        isScrollingProgrammatically = true
        autoscrollTimerTime = 0
        currentLineIndex = 0
        
        scrollTimer?.invalidate()
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.autoscrollTimerTime += 0.5
            
            if currentLineIndex < timestamps.count {
                let components = timestamps[currentLineIndex].split(separator: "_")
                if components.count == 2,
                   let lineIndex = Int(components[0]),
                   let targetTime = Double(components[1]),
                   autoscrollTimerTime >= targetTime {
                    DispatchQueue.main.async {
                        withAnimation {
                            scrollViewProxy.scrollTo(lineIndex, anchor: performanceMode ? .center : .top)
                        }
                    }
                    self.currentLineIndex += 1
                    
                    if currentLineIndex >= timestamps.count {
                        self.scrollTimer?.invalidate()
                        self.isScrolling = false
                        self.autoscrollTimerTime = 0
                    }
                }
            } else {
                self.scrollTimer?.invalidate()
                self.isScrolling = false
            }
        }
    }
    func scrollTo(_ index: Int) {
        if let scrollViewProxy = proxy {
            withAnimation {
                scrollPosition = index
                scrollViewProxy.scrollTo(Int(scrollPosition), anchor: performanceMode ? .center : .top)
                currentLineIndex = scrollPosition
            }
        }
    }
    func stopAutoscroll(scrollViewProxy: ScrollViewProxy) {
        isScrolling = false
        scrollTimer?.invalidate()
        scrollTimer = nil
        scrollTo(0)
    }
    func startTimer() {
        stopTimer()
        
        loadSounds()
        
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
    func stopTimer() {
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
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                if metronomeStyle.contains("Audio") {
                    clickAudioPlayer?.play()
                }
            case .heavy:
                if metronomeStyle.contains("Vibrations") {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
                if metronomeStyle.contains("Audio") {
                    accentAudioPlayer?.play()
                }
            }
        }
    }
    func alignment(from alignment: TextAlignment) -> Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
    func hAlignment(from alignment: TextAlignment) -> HorizontalAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
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
    func startCountdown(completion: @escaping() -> Void) {
        countdown = 3
        showCountdown = true
        isScrollingProgrammatically = true
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                stopCountdown()
                completion()
            }
        }
    }
    func stopCountdown() {
        countdownTimer?.invalidate()
        withAnimation {
            showCountdown = false
        }
    }
    func recordTimestamp() {
        isScrollingProgrammatically = true
        guard currentLineIndex < lines.count else { return }
        let timestamp = String(currentTime)
        
        print(timestamp)
        
        let timestampString = "\(currentLineIndex)_\(timestamp)"
        timestamps.append(timestampString)
        
        if currentLineIndex < lines.count - 1 {
            currentLineIndex += 1
            scrollTo(currentLineIndex)
        } else {
            isSyncing = false
            scrollTo(0)
            syncLyricTimer?.invalidate()
            syncLyricTimer = nil
            print("Final timestamps: \(timestamps)")
            songViewModel.updateTimestamps(for: song, with: timestamps)
        }
    }
    
    func formatTime(_ time: Double) -> String {
        return String(format: "%.2f", time)
    }
    
    init(song: Song, size: Int, design: Font.Design, weight: Font.Weight, lineSpacing: Double, alignment: TextAlignment, key: String, title: String, lyrics: String, duration: Binding<String>, bpm: Binding<Int>, bpb: Binding<Int>, performanceMode: Binding<Bool>, songs: [Song]?, dismiss: Binding<Bool>) {
        self.songs = songs
        self._key = State(initialValue: key)
        self._title = State(initialValue: title)
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.design = design
        self.weight = weight
        self.size = size
        self.currentIndex = song.order ?? 0
        self.timestamps = song.timestamps ?? []
        self._bpb = bpb
        self._bpm = bpm
        self._performanceMode = performanceMode
        self._duration = duration
        self._song = State(initialValue: song)
        self._lyrics = State(initialValue: lyrics)
        self._dismiss = dismiss
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    VStack(spacing: 0) {
                        HStack {
                            Text(title)
                                .font(.title2.weight(.bold))
                                .lineLimit(1).truncationMode(.tail)
                            Spacer()
                            if key != "" && key != "Not Set" {
                                Text("Key: " + key)
                                    .foregroundColor(Color.gray)
                                    .padding(.trailing, 6)
                            }
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
                            Button(action: {
                                stopTimer()
                                dismiss = false
                            }) {
                                Image(systemName: "xmark")
                                    .imageScale(.medium)
                                    .padding(12)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .background(Material.regular)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(hasHomeButton() ? .top : [])
                        .padding([.horizontal, .bottom])
                        Divider()
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: hAlignment(from: alignment), spacing: performanceMode ? 25 : lineSpacing) {
                                    ForEach(lines.indices, id: \.self) { index in
                                        let line = lines[index]
                                        
                                        if !performanceMode {
                                            Text(line)
                                                .frame(maxWidth: .infinity, alignment: alignment(from: alignment))
                                                .font(.system(size: CGFloat(size), weight: weight, design: design))
                                                .id(index)
                                                .blur(radius: getBlur(for: index))
                                                .animation(.spring(dampingFraction: 1.0))
                                        } else {
                                            Button {
                                                scrollTo(index)
                                            } label: {
                                                Text(line)
                                                    .frame(maxWidth: .infinity, alignment: alignment(from: alignment))
                                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                                    .foregroundColor(.primary)
                                                    .id(index)
                                                    .padding(5)
                                                    .scaleEffect((isPressed && pressedIndexId == index) ? 0.85 : 1)
                                                    .background((isPressed && pressedIndexId == index) ? Color.materialRegularGray.opacity(0.75) : .clear)
                                                    .cornerRadius(10)
                                                    .blur(radius: (isPressed && pressedIndexId == index) ? 0 : getBlur(for: index))
                                                    .animation(.spring(dampingFraction: 1.0))
                                            }
                                            .buttonStyle(ScaleButtonStyle(isPressed: $isPressed, pressedIndexId: $pressedIndexId, index: index))
                                        }
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
                                            .cornerRadius(8)
                                    }
                                    .onChange(of: bpm) { bpm in
                                        songViewModel.updateBpm(for: song, with: bpm)
                                    }
                                    Menu {
                                        Button {
                                            bpb = 1
                                        } label: {
                                            Label("1", systemImage: bpb == 1 ? "checkmark" : "")
                                        }
                                        Button {
                                            bpb = 2
                                        } label: {
                                            Label("2", systemImage: bpb == 2 ? "checkmark" : "")
                                        }
                                        Button {
                                            bpb = 3
                                        } label: {
                                            Label("3", systemImage: bpb == 23 ? "checkmark" : "")
                                        }
                                        Button {
                                            bpb = 4
                                        } label: {
                                            Label("4", systemImage: bpb == 4 ? "checkmark" : "")
                                        }
                                        Button {
                                            bpb = 5
                                        } label: {
                                            Label("5", systemImage: bpb == 5 ? "checkmark" : "")
                                        }
                                        Button {
                                            bpb = 6
                                        } label: {
                                            Label("6", systemImage: bpb == 6 ? "checkmark" : "")
                                        }
                                        Button {
                                            bpb = 7
                                        } label: {
                                            Label("7", systemImage: bpb == 7 ? "checkmark" : "")
                                        }
                                        Button {
                                            bpb = 8
                                        } label: {
                                            Label("8", systemImage: bpb == 8 ? "checkmark" : "")
                                        }
                                    } label: {
                                        Text("\(bpb) BPB")
                                            .padding(10)
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                            .background(Material.regular)
                                            .cornerRadius(8)
                                    }
                                    .onChange(of: bpb) { bpb in
                                        songViewModel.updateBpm(for: song, with: bpb)
                                    }
                                    Spacer()
                                    if isPulsing {
                                        Circle()
                                            .frame(width: 12, height: 12)
                                            .foregroundColor(.primary)
                                    }
                                    Button {
                                        if isPlayingMetronome {
                                            stopTimer()
                                        } else {
                                            startTimer()
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
                                            .padding()
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.white)
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
                VStack(spacing: 12) {
                    if timestamps.isEmpty && !showSyncControls {
                        Group {
                            Text("Your lyrics have not yet been synced. ").foregroundColor(.gray) + Text("Sync them?").foregroundColor(.blue).font(.body.weight(.medium))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            showSyncControls = true
                        }
                    }
                    HStack {
                        if !showSyncControls {
                            if songs != nil {
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
                            if viewModel.currentUser?.enableAutoscroll ?? true && lines.count > 1 {
                                let buttons = HStack {
                                    Button(action: {
                                        if let proxy = proxy {
                                            if isScrolling {
                                                stopAutoscroll(scrollViewProxy: proxy)
                                            } else {
                                                startCountdown {
                                                    startAutoscroll(scrollViewProxy: proxy)
                                                }
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: isScrolling ? "stop" : "play")
                                            Text(isScrolling ? "Stop" : NSLocalizedString("autoscroll", comment: "Autoscroll"))
                                        }
                                        .imageScale(.medium)
                                        .padding()
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.white)
                                        .background(isScrolling ? .red : .blue)
                                        .clipShape(Capsule())
                                    }
                                    Menu {
                                        Button {
                                            performanceMode.toggle()
                                        } label: {
                                            Label("Performance Mode", systemImage: performanceMode ? "checkmark" : "")
                                        }
                                        Button {
                                            showSyncControls = true
                                        } label: {
                                            Label("Sync Lyrics", systemImage: "arrow.triangle.2.circlepath")
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
                                if #available(iOS 17, *) {
                                    buttons
                                        .showAutoscrollSpeedTip()
                                } else {
                                    buttons
                                }
                            }
                            Spacer()
                            if songs != nil {
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
                        } else {
                            VStack(spacing: 12) {
                                HStack {
                                    Button {
                                        recordTimestamp()
                                    } label: {
                                        HStack {
                                            Text("Next Line")
                                            Image(systemName: "chevron.down")
                                                .offset(y: 1.5)
                                        }
                                        .imageScale(.medium)
                                        .padding()
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.white)
                                        .background(.blue)
                                        .clipShape(Capsule())
                                    }
                                    .disabled(!isSyncing)
                                    .opacity(!isSyncing ? 0.5 : 1)
                                    Button {
                                        if !showCountdown {
                                            if !isSyncing {
                                                startCountdown {
                                                    isSyncing = true
                                                    syncLyricTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                                                        currentTime += 0.5
                                                    }
                                                }
                                            } else {
                                                scrollTo(0)
                                                isSyncing = false
                                                syncLyricTimer?.invalidate()
                                                syncLyricTimer = nil
                                            }
                                        } else {
                                            showCountdown = false
                                            stopCountdown()
                                        }
                                    } label: {
                                        FAText(iconName: isSyncing ? "stop" : "play", size: 22)
                                            .padding(17)
                                            .offset(x: isSyncing ? 0 : 2.2)
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.white)
                                            .background(isSyncing ? .red : .blue)
                                            .clipShape(Circle())
                                    }
                                    Spacer()
                                    Button {
                                        showSyncControls = false
                                    } label: {
                                        Image(systemName: "xmark")
                                            .padding()
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.white)
                                            .background(Material.regular)
                                            .clipShape(Circle())
                                    }
                                }
                                Text("To sync your lyrics, press the 'Next Line' button every time the lyrics should scroll to the next line.")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding([.horizontal, .top])
                .padding(hasHomeButton() ? .bottom : [])
            }
            if showCountdown {
                Text(String(countdown))
                    .font(.system(size: 65).weight(.bold))
                    .padding(20)
                    .frame(width: 90, height: 90)
                    .background(Material.regular)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
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
    @Binding var isPressed: Bool
    @Binding var pressedIndexId: Int
    let index: Int
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { isPressed in
                self.isPressed = isPressed
                self.pressedIndexId = index
            }
    }
}
