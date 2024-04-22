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
    @State var title = ""
    @State var key = ""
    @State var selectedTool = ""
    
    @State private var scrollPosition: Int = 0
    @State private var currentLineIndex: Int = 0
    @State private var scrollTimer: Timer?
    @State private var linesHeight: CGFloat = 0.0
    @State private var beatCounter: Int = 0
    @State private var pressedIndexId: Int = 0
    
    @State var isPlayingMetronome = false
    @State var isPulsing = false
    @State var isHeavyImpactPlaying = false
    @State var isScrolling = false
    @State var isUserScrolling = false
    @State var isScrollingProgrammatically = true
    @State var isPressed = false
    @State var isRecording = false
    @State var showTakesView = false
    
    @State var proxy: ScrollViewProxy?
    
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
    func startAutoscroll(scrollViewProxy: ScrollViewProxy) {
        isScrolling = true
        isScrollingProgrammatically = true
        
        var duration = "2:00"
        if !self.duration.isEmpty || self.duration != "" {
            duration = self.duration
        }
        
        scrollTimer = Timer.scheduledTimer(withTimeInterval: durationStringToSeconds(duration) / Double(lines.count), repeats: true) { _ in
            withAnimation {
                isScrollingProgrammatically = true
                
                if currentLineIndex >= lines.count {
                    currentLineIndex = 0
                    scrollTo(0)
                    scrollTimer?.invalidate()
                    isScrolling = false
                } else {
                    scrollPosition = currentLineIndex + 1
                    scrollViewProxy.scrollTo(Int(scrollPosition), anchor: performanceMode ? .center : .top)
                    currentLineIndex += 1
                }
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
        withAnimation {
            scrollViewProxy.scrollTo(0, anchor: .top)
        }
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
    
    init(song: Song, size: Int, design: Font.Design, weight: Font.Weight, lineSpacing: Double, alignment: TextAlignment, key: String, title: String, lyrics: String, duration: Binding<String>, bpm: Binding<Int>, bpb: Binding<Int>, performanceMode: Binding<Bool>, songs: [Song]?, dismiss: Binding<Bool>) {
        self.songs = songs
        self._key = State(initialValue: key)
        self._currentIndex = State(initialValue: song.order ?? 0)
        self._title = State(initialValue: title)
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.design = design
        self.weight = weight
        self.size = size
        self._bpb = bpb
        self._bpm = bpm
        self._performanceMode = performanceMode
        self._duration = duration
        self._song = State(initialValue: song)
        self._lyrics = State(initialValue: lyrics)
        self._dismiss = dismiss
    }
    
    var body: some View {
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
                        Menu {
                            Button {
                                if selectedTool == "takes" {
                                    selectedTool = ""
                                } else {
                                    selectedTool = "takes"
                                }
                            } label: {
                                Label("Takes", systemImage: selectedTool == "takes" ? "checkmark" : "")
                            }
                            Button {
                                if selectedTool == "metronome" {
                                    selectedTool = ""
                                } else {
                                    selectedTool = "metronome"
                                }
                            } label: {
                                Label("Metronome", systemImage: selectedTool == "metronome" ? "checkmark" : "")
                            }
                        } label: {
                            FAText(iconName: "toolbox", size: 19)
                                .padding(12)
                                .font(.body.weight(.semibold))
                                .foregroundColor(selectedTool == "metronome" ? .white : .primary)
                                .background(selectedTool == "metronome" ? .blue : .materialRegularGray)
                                .foregroundColor(selectedTool != "" ? .white : .primary)
                                .background(selectedTool != "" ? .blue : .materialRegularGray)
                                .clipShape(Circle())
                        }
                        Button(action: {
                            if let proxy = proxy {
                                stopAutoscroll(scrollViewProxy: proxy)
                            }
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
                                        .padding(15)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.white)
                                        .background(Material.regular)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(12)
                    case "takes":
                        TakesMiniView(showTakesView: $showTakesView, isDisplayed: $dismiss, song: song)
                            .popover(isPresented: $showTakesView) {
                                SongTakesView(isPresented: $showTakesView, song: song)
                            }
                    default:
                        EmptyView()
                    }
                }
            }
            Divider()
            HStack {
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
                                    startAutoscroll(scrollViewProxy: proxy)
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
            }
            .padding([.horizontal, .top])
            .padding(hasHomeButton() ? .bottom : [])
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
