//
//  TakesMiniView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/22/24.
//

import SwiftUI
import AVFoundation
import BottomSheet

struct TakesMiniView: View {
    @Binding var isDisplayed: Bool
    
    @State private var showBorder = false
    @State private var hasMicPermission = false
    @State private var showTakesView = false
    
    @State private var borderColor = Color.red
    
    let song: Song
    
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var takesViewModel = TakesViewModel.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: hasMicPermission ? 6 : 10) {
            Text("TAKES")
                .font(.caption.weight(.semibold))
            HStack {
                if hasMicPermission {
                    Text(songViewModel.timeFormatted(takesViewModel.elapsedTime))
                        .padding(10)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .background(Material.regular)
                        .cornerRadius(8)
                    Spacer()
                    Button {
                        if takesViewModel.isRecording {
                            self.takesViewModel.stopRecording(song: song) {}
                        } else {
                            self.takesViewModel.startRecording(song: song)
                        }
                    } label: {
                        FAText(iconName: takesViewModel.isRecording ? "stop" : "microphone", size: 22)
                            .padding()
                            .padding(.trailing, takesViewModel.isRecording ? 0 : -2)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .background(takesViewModel.isRecording ? .red : .blue)
                            .clipShape(Circle())
                    }
                    Button {
                        showTakesView = true
                    } label: {
                        Image(systemName: "chevron.up")
                            .padding(18)
                            .offset(y: -1)
                            .font(.system(size: 18).weight(.medium))
                            .foregroundColor(showBorder ? .blue : .white)
                            .background(Material.regular)
                            .clipShape(Circle())
                            .overlay {
                                if showBorder {
                                    Circle()
                                        .stroke(.blue, lineWidth: 2.5)
                                        .onAppear {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                withAnimation(.easeInOut) {
                                                    showBorder = false
                                                }
                                            }
                                        }
                                }
                            }
                    }
                    .onChange(of: takesViewModel.isRecording) { isRecording in
                        if !isRecording {
                            withAnimation(.easeInOut) {
                                showBorder = true
                            }
                        }
                    }
                    Button {
                        isDisplayed = false
                    } label: {
                        Image(systemName: "xmark")
                            .padding(15)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                } else {
                    Group {
                        Text("To record takes, please allow Live Lyrics to use the microphone in ") + Text("Settings").foregroundColor(.blue) + Text(".")
                    }
                    .onTapGesture {
                        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                        if UIApplication.shared.canOpenURL(settingsURL) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(1.1)
                }
            }
        }
        .padding(12)
        .onAppear {
            takesViewModel.audioSession.requestRecordPermission { response in
                hasMicPermission = response
            }
        }
        .bottomSheet(isPresented: $showTakesView, detents: [.medium(), .large()]) {
            SongTakesView(isPresented: $showTakesView, song: song)
        }
    }
}

#Preview {
    TakesMiniView(isDisplayed: .constant(true), song: Song.song)
}
