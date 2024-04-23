//
//  SongTakesView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/22/24.
//

import SwiftUI
import AVFoundation
import BottomSheet

struct SongTakesView: View {
    @Binding var isPresented: Bool
    
    @State private var takeToEdit: Take?
    @State private var recordedTake: Take?
    
    @State private var showBorder = false
    @State private var showTakeEditView = false
    @State private var showTakeDetailView = false
    @State private var showDeleteConfirmation = false
    
    @ObservedObject var takesViewModel = TakesViewModel.shared
    
    @FocusState var isFocused: Bool
    
    var song: Song
    
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
                                            self.showTakeDetailView = true
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
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Material.regular)
                                            .foregroundColor(.gray)
                                            .cornerRadius(20)
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
                                                    showDeleteConfirmation = true
                                                }) {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                        .bottomSheet(isPresented: $showTakeDetailView, detents: [.medium()]) {
                                            TakeDetailView(isPresented: $showTakeDetailView, take: take, song: song)
                                        }
                                        .confirmationDialog("Delete Take", isPresented: $showDeleteConfirmation) {
                                            Button("Delete", role: .destructive) {
                                                takesViewModel.deleteTake(take, song: song)
                                            }
                                            Button("Cancel", role: .cancel) {}
                                        } message: {
                                            Text("Are you sure you want to delete '\(take.title ?? "Take \((takesViewModel.recordedTakes.firstIndex(of: take) ?? 0) + 1)")'?")
                                        }
                                    }
                                }
                            }
                            .padding()
                            .sheet(isPresented: $showTakeEditView) {
                                let take = Take(url: takeToEdit?.url ?? URL(string: "")!, date: takeToEdit?.date ?? Date(), songId: takeToEdit?.songId ?? "", title: takeToEdit?.title ?? "")
                                
                                TakeEditView(isDisplayed: $showTakeEditView, titleToUpdate: .constant(""), song: song, take: take)
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
                                takesViewModel.stopRecording(song: song) {
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
                takesViewModel.loadRecordedTakes(forSong: song)
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct AnimatedCircleView: View {
    let color: Color
    @State private var blur: CGFloat = 15
    
    let animationTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    init(color: Color? = nil) {
        self.color = color ?? .red
    }
    
    var body: some View {
        color
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

