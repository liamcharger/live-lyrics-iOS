//
//  SongDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import SwiftUI
import BottomSheet
import UIKit

struct SongFullScreenView: View {
    @Binding var dismiss: Bool
    @Binding var hasDeletedSong: Bool
    
    @State var song: Song
    
    @State private var currentIndex = 0
    @State private var offset: CGFloat = 0
    
    @State var lyrics = ""
    @State var lyricsCollection = [""]
    @State var title = ""
    @State var key = ""
    @State var selectedTool = ""
    @State var bpm = ""
    @State var bpb = 4
    
    @State private var scrollPosition: CGFloat = 0
    @State private var currentLineIndex: Int = 0
    @State private var scrollTimer: Timer?
    @State private var linesHeight: CGFloat = 0.0
    
    @State var performanceView = false
    @State var isPlayingMetronome = false
    
    @State var proxy: ScrollViewProxy?
    
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel.shared
    @EnvironmentObject var viewModel: AuthViewModel
    
    @Environment(\.presentationMode) var presMode
    
    var songs: [Song]?
    
    let size: Int
    let weight: Font.Weight
    let design: Font.Design
    let lineSpacing: Double
    let alignment: TextAlignment
    
    @Binding var duration: String
    
    @State var isScrolling = false
    
    var lines: [String] {
        return lyrics.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    var autoscrollButton: some View {
        Button(action: {
            if let proxy = proxy {
                if isScrolling {
                    stopAutoscroll(scrollViewProxy: proxy)
                } else {
                    isScrolling = true
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
    }
    func swipeLeft() {
        currentIndex += 1
        if currentIndex >= songs!.count {
            currentIndex = 0
        }
        self.song = self.songs![currentIndex]
        self.lyrics = self.song.lyrics
        self.title = song.title
        self.key = song.key ?? "Not Set"
        self.duration = song.duration ?? "1:00"
        if let proxy = proxy, isScrolling {
            stopAutoscroll(scrollViewProxy: proxy)
        }
    }
    func swipeRight() {
        currentIndex -= 1
        if currentIndex < 0 {
            currentIndex = songs!.count - 1
        }
        self.song = self.songs![currentIndex]
        self.lyrics = self.song.lyrics
        self.title = song.title
        self.key = song.key ?? "Not Set"
        self.duration = song.duration ?? "1:00"
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
        
        scrollTimer = Timer.scheduledTimer(withTimeInterval: durationStringToSeconds(duration) / Double(lines.count), repeats: true) { _ in
            if isScrolling {
                withAnimation {
                    scrollPosition = CGFloat(currentLineIndex + 1)
                    scrollViewProxy.scrollTo(Int(scrollPosition), anchor: .top)
                    currentLineIndex += 1
                    
                    if currentLineIndex >= lines.count {
                        scrollTimer?.invalidate()
                        isScrolling = false
                    }
                    
                    print(currentLineIndex)
                }
            }
        }
    }
    func stopAutoscroll(scrollViewProxy: ScrollViewProxy) {
        isScrolling = false
        scrollTimer = nil
        currentLineIndex = 0
        withAnimation {
            scrollViewProxy.scrollTo(0, anchor: .top)
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
    
    init(song: Song, size: Int, design: Font.Design, weight: Font.Weight, lineSpacing: Double, alignment: TextAlignment, key: String, title: String, lyrics: String, duration: Binding<String>, songs: [Song]?, dismiss: Binding<Bool>, hasDeletedSong: Binding<Bool>) {
        self.songs = songs
        self._key = State(initialValue: key)
        self._currentIndex = State(initialValue: song.order ?? 0)
        self._title = State(initialValue: title)
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.design = design
        self.weight = weight
        self.size = size
        self._duration = duration
        self._song = State(initialValue: song)
        self._lyrics = State(initialValue: lyrics)
        self._dismiss = dismiss
        self._hasDeletedSong = hasDeletedSong
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
//                        Menu {
//                            Button {
//                                if selectedTool == "metronome" {
//                                    selectedTool = ""
//                                } else {
//                                    selectedTool = "metronome"
//                                }
//                            } label: {
//                                Label("Metronome", systemImage: selectedTool == "metronome" ? "checkmark" : "")
//                            }
//                        } label: {
//                            FAText(iconName: "toolbox", size: 18)
//                                .imageScale(.medium)
//                                .padding(12)
//                                .font(.body.weight(.semibold))
//                                .foregroundColor(.primary)
//                                .background(Material.regular)
//                                .clipShape(Circle())
//                        }
                        SheetCloseButton(isPresented: $dismiss)
                    }
                    .padding(hasHomeButton() ? .top : [])
                    .padding(.horizontal)
                    Divider()
                        .padding(.top)
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: hAlignment(from: alignment), spacing: lineSpacing) {
                                ForEach(lines.indices, id: \.self) { index in
                                    let line = lines[index]
                                    
                                    Text(line)
                                        .frame(maxWidth: .infinity, alignment: alignment(from: alignment))
                                        .font(.system(size: CGFloat(size), weight: weight, design: design))
                                        .id(index)
                                }
                            }
                            .padding()
                        }
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
                                Text("120 BPM")
                                    .padding(10)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .background(Material.regular)
                                    .cornerRadius(8)
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
                                Spacer()
                                Button {
                                    if isPlayingMetronome {
                                        // Stop metronome
                                    } else {
                                        // Start metronome
                                    }
                                    // SIMULATE
                                    isPlayingMetronome.toggle()
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
                if viewModel.currentUser?.enableAutoscroll ?? true {
                    if #available(iOS 17, *) {
                        autoscrollButton
                            .showAutoScrollSpeedTip()
                    } else {
                        autoscrollButton
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
            if song.autoscrollDuration != nil || song.autoscrollDuration == "" {
                self.duration = song.autoscrollDuration ?? ""
            } else if song.duration != nil {
                self.duration = song.duration ?? ""
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
