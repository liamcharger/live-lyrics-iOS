//
//  SongTakesView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/22/24.
//

import SwiftUI
import AVFoundation

struct SongTakesView: View {
    @Binding var isPresented: Bool
    
    @State private var selectedTake: Take?
    @State private var takeToEdit: Take?
    @State private var recordedTake: Take?
    
    @State private var isPlaying = false
    @State private var showBorder = false
    @State private var showTakeEditView = false
    
    @State private var title = ""
    
    @State private var audioPlayer: AVAudioPlayer?
    
    @ObservedObject var takesViewModel = TakesViewModel.shared
    
    @FocusState var isFocused: Bool
    
    let song: Song
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("Takes")
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                    Spacer()
                    SheetCloseButton(isPresented: $isPresented, padding: 16)
                }
                .padding()
                Divider()
                if !takesViewModel.isRecording {
                    if takesViewModel.recordedTakes.isEmpty {
                        FullscreenMessage(imageName: "circle.slash", title: "It doesn't look like you've recorded any takes for this song.", spaceNavbar: true)
                    } else {
                        ScrollView {
                            VStack {
                                ForEach(takesViewModel.recordedTakes.reversed(), id: \.id) { take in
                                    VStack(spacing: 0) {
                                        Button(action: {
                                            withAnimation(.bouncy(extraBounce: 0.1)) {
                                                if selectedTake == take {
                                                    selectedTake = nil
                                                } else {
                                                    selectedTake = take
                                                }
                                            }
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(take.title ?? "Take \(takesViewModel.recordedTakes.firstIndex(where: { $0.id == take.id })?.advanced(by: 1).description ?? "")")
                                                        .font(.title2.weight(.semibold))
                                                        .foregroundColor(showBorder && (recordedTake?.id == take.id) ? Color.blue : Color.primary)
                                                    Text(take.date.formatted())
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .rotationEffect(selectedTake == take ? Angle(degrees: 90) : Angle(degrees: 0))
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Material.regular)
                                            .foregroundColor(.gray)
                                            .cornerRadius(20, corners: selectedTake == take ? [.topLeft, .topRight] : [.allCorners])
                                            .overlay {
                                                if showBorder && recordedTake == take {
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(Color.blue, lineWidth: 3.5)
                                                        .onAppear {
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                                withAnimation(.easeInOut) {
                                                                    showBorder = false
                                                                }
                                                            }
                                                        }
                                                }
                                            }
                                            .contextMenu {
                                                // TODO: Make available to older iOS versions
                                                if #available(iOS 16, *) {
                                                    ShareLink(item: take.url, subject: Text("\((takesViewModel.recordedTakes.firstIndex(of: take) ?? 0) + 1)"))
                                                }
                                                Button {
                                                    takeToEdit = take
                                                    showTakeEditView = true
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                Button(role: .destructive, action: {
                                                    takesViewModel.deleteTake(take)
                                                }) {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                        if selectedTake == take {
                                            VStack(spacing: 14) {
                                                Divider()
                                                    .padding(.horizontal, -16)
                                                HStack {
                                                    Button {
                                                        do {
                                                            self.audioPlayer = try AVAudioPlayer(contentsOf: take.url)
                                                            
                                                            if let audioPlayer = audioPlayer {
                                                                if !isPlaying {
                                                                    audioPlayer.play()
                                                                    isPlaying = true
                                                                } else {
                                                                    audioPlayer.pause()
                                                                    isPlaying = false
                                                                }
                                                            }
                                                        } catch {
                                                            print(error.localizedDescription)
                                                        }
                                                    } label: {
                                                        Image(systemName: isPlaying ? "pause" : "play")
                                                            .padding(10)
                                                            .background(isPlaying ? Color.red : Color.blue)
                                                            .foregroundColor(.white)
                                                            .cornerRadius(6)
                                                    }
                                                    .onChange(of: audioPlayer?.isPlaying ?? false) { isPlaying in
                                                        if !isPlaying {
                                                            self.isPlaying = false
                                                        }
                                                    }
                                                }
                                            }
                                            .padding([.horizontal, .bottom], 14)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Material.regular)
                                            .foregroundColor(.gray)
                                            .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                                        }
                                    }
                                }
                            }
                            .padding()
                            .sheet(isPresented: $showTakeEditView) {
                                VStack(spacing: 0) {
                                    HStack(alignment: .center, spacing: 10) {
                                        Text("Edit Take")
                                            .font(.title.weight(.bold))
                                        Spacer()
                                        SheetCloseButton(isPresented: $showTakeEditView)
                                    }
                                    .padding()
                                    Divider()
                                    ScrollView {
                                        CustomTextField(text: $title, placeholder: "Title")
                                            .focused($isFocused)
                                            .padding()
                                    }
                                    Divider()
                                    Button(action: {
                                        takesViewModel.updateTake(takeToEdit, title: title)
                                        showTakeEditView = false
                                    }) {
                                        Text(NSLocalizedString("save", comment: "Save"))
                                            .frame(maxWidth: .infinity)
                                            .modifier(NavButtonViewModifier())
                                    }
                                    .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                                    .padding()
                                }
                                .onAppear {
                                    isFocused = true
                                }
                            }
                        }
                    }
                    if !takesViewModel.recordedTakes.isEmpty {
                        Divider()
                        Text("Takes are not synced across devices.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                } else {
                    VStack(spacing: 22) {
                        Spacer()
                        Text("Recording...")
                            .font(.title.weight(.bold))
                        ZStack {
                            AnimatedCircleView()
                            Button {
                                takesViewModel.stopRecording {
                                    withAnimation {
                                        showBorder = true
                                        recordedTake = takesViewModel.recordedTake
                                    }
                                }
                            } label: {
                                FAText(iconName: "stop", size: 35)
                                    .padding(20)
                                    .background(takesViewModel.isRecording ? Color.red : Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .animation(.none)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .onAppear {
                takesViewModel.loadRecordedTakes()
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct AnimatedCircleView: View {
    @State private var blur: CGFloat = 15
    
    let animationTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Color.red
            .frame(width: 75, height: 75)
            .clipShape(Circle())
            .blur(radius: blur)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 1.0)) {
                        blur = CGFloat.random(in: 15...55)
                    }
                }
            }
    }
}

