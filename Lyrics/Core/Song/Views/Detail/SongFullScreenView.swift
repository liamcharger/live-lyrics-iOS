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
    
    @State private var autoScrollTimer: Timer?
    
    @State private var currentIndex = 0
    @State private var offset: CGFloat = 0
    
    @State var lyrics = ""
    @State var lyricsCollection = [""]
    @State var title = ""
    @State var key = ""
    
    @State private var scrollPosition: CGFloat = 0
    @State private var currentLineIndex: Int = 0
    @State private var scrollTimer: Timer?
    @State private var linesHeight: CGFloat = 0.0
    
    @State var performanceView = false
    
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel()
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
    
    @State private var contentOffset: CGPoint = .zero
    
    var lines: [String] {
        return lyrics.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    var computedAlignment: HorizontalAlignment {
        switch(alignment) {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
    
    // Functions
    func swipeLeft() {
        currentIndex += 1
        if currentIndex >= songs!.count {
            currentIndex = 0
        }
        self.song = self.songs![currentIndex]
        self.lyrics = self.song.lyrics
        self.title = song.title
        self.key = song.key ?? "Not Set"
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
        
        //        scrollTimer = Timer.scheduledTimer(withTimeInterval: durationStringToSeconds(duration) / Double(lines.count), repeats: true) { _ in
        //            if isScrolling {
        //                withAnimation {
        //                    scrollPosition = CGFloat(currentLineIndex + 1)
        //                    scrollViewProxy.scrollTo(scrollPosition, anchor: .top)
        //                    currentLineIndex += 1
        //
        //                    if currentLineIndex >= lines.count {
        //                        scrollTimer?.invalidate()
        //                    }
        //                }
        //            }
        //        }
    }
    
    // Initialization
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
                        Text("Key: " + key == "" ? "Not Set" : key)
                            .foregroundColor(Color.gray)
                            .padding(.trailing, 6)
                        SheetCloseButton(isPresented: $dismiss)
                    }
                    .padding(hasHomeButton() ? .top : [])
                    .padding(.horizontal)
                    Divider()
                        .padding(.top)
                    ScrollView {
//                        ScrollableView(self.$contentOffset, animationDuration: durationStringToSeconds(duration)) {
                        HStack {
//                            if viewModel.currentUser?.enableAutoscroll ?? true {
//                            if false {
//                                HStack {
//                                    Button {
//                                        if isScrolling {
//                                            isScrolling = false
//                                        } else {
//                                            // Calculate the height of all lines
//                                            let text = lyrics.split(separator: "\n")
//                                            let lineHeight = geometry.size.height / CGFloat(text.count)
//                                            linesHeight = lineHeight * CGFloat(text.count)
//                                            
//                                            // Scroll to the top of the lyrics
//                                            self.contentOffset = CGPoint(x: 0, y: 0)
//                                            
//                                            // Start autoscrolling
//                                            self.contentOffset = CGPoint(x: 0, y: linesHeight)
//                                            isScrolling = true
//                                        }
//                                    } label: {
//                                        HStack(spacing: 8) {
//                                            Image(systemName: isScrolling ? "stop" : "play")
//                                            Text(isScrolling ? "Stop" : NSLocalizedString("autoscroll", comment: "Autoscroll"))
//                                        }
//                                        .modifier(NavButtonViewModifier())
//                                    }
//                                    .onChange(of: isScrolling) { value in
//                                        if value == false {
//                                            withAnimation {
//                                                self.contentOffset = CGPoint(x: 0, y: 0)
//                                            }
//                                        }
//                                    }
//                                    Button {
//                                        showSettingsView.toggle()
//                                    } label: {
//                                        Text(duration == "" ? "0:00" : duration)
//                                            .padding()
//                                            .font(.body.weight(.semibold))
//                                            .background(Material.regular)
//                                            .foregroundColor(.primary)
//                                            .clipShape(Capsule())
//                                    }
//                                    Spacer()
//                                    Menu {
//                                        Button {
//                                            performanceView.toggle()
//                                            hapticByStyle(.medium)
//                                        } label: {
//                                            Label("Show Performance View", systemImage: performanceView ? "checkmark" : "")
//                                        }
//                                    } label: {
//                                        Image(systemName: "gear")
//                                            .padding()
//                                            .font(.body.weight(.semibold))
//                                            .foregroundColor(Color("Color"))
//                                            .background(Material.regular)
//                                            .cornerRadius(30)
//                                    }
//                                }
//                                .padding(.top, 8)
//                                .padding(.bottom, -10)
//                                .padding(.horizontal)
//                                Divider()
//                                    .padding(.top)
//                            }
                            Text(lyrics)
                                .font(.system(size: CGFloat(size), weight: weight, design: design))
                                .multilineTextAlignment(alignment)
                                .lineSpacing(CGFloat(lineSpacing))
                                .padding()
                            Spacer()
                        }
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
                if isScrolling {
                    Button(action: {
                        isScrolling = false
                        autoScrollTimer = nil
                        currentLineIndex = 0
                    }) {
                        HStack {
                            Image(systemName: "stop")
                            Text("Stop")
                        }
                        .imageScale(.medium)
                        .padding()
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .background(Material.regular)
                        .clipShape(Capsule())
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
