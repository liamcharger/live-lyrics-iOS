//
//  SongSettingsView.swift
//  Lyrics
//
//  Created by Liam Willey on 10/24/23.
//

import SwiftUI

struct SongSettingsView: View {
    @Environment(\.presentationMode) var presMode
    @ObservedObject var songSettingsViewModel = SongSettingsViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    
    var song: Song
    var folder: Folder?
    
    @Binding var autoscrollDuration: String
    @Binding var hasDeletedSong: Bool
    
    @State var minutes = 0
    @State var seconds = 0
    
    @State var showDeleteSheet = false
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("More")
                    .font(.title2.weight(.bold))
                Spacer()
                Button(action: {presMode.wrappedValue.dismiss()}) {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color("Color"))
                        .background(Material.regular)
                        .clipShape(Circle())
                }
            }
            .padding(.bottom)
            Divider().padding(.horizontal, -16)
            ScrollView(showsIndicators: false) {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(NSLocalizedString("autoscroll", comment: "Autoscroll") + " " + NSLocalizedString("duration", comment: "Duration").lowercased())
                                Text("\(minutes):\(seconds < 10 ? "0" + String(seconds) : String(seconds))")
                                    .font(.body.weight(.semibold))
                            }
                            Divider()
                            VStack {
                                HStack {
                                    Text("Mins")
                                    Spacer()
                                    Text("\(minutes)")
                                        .foregroundColor(.gray)
                                    Stepper("Mins", value: $minutes, in: 0...60)
                                }
                                HStack {
                                    Text("Secs")
                                    Spacer()
                                    Text("\(seconds)")
                                        .foregroundColor(.gray)
                                    Stepper("Secs", value: $seconds, in: 0...60)
                                }
                            }
                            .labelsHidden()
                            .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background {
                        Rectangle()
                            .fill(.clear)
                            .background(Material.regular)
                            .mask { RoundedRectangle(cornerRadius: 20) }
                    }
                    .foregroundColor(.primary)
                    Button {
                        let totalSeconds = durationStringToSeconds(song.duration ?? "")
                        
                        minutes = Int(totalSeconds / 60)
                        seconds = Int(totalSeconds) % 60
                    } label: {
                        Text("Use Song Duration")
                            .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            Rectangle()
                                .fill(.clear)
                                .background(Material.regular)
                                .mask { RoundedRectangle(cornerRadius: 20) }
                        }
                        .foregroundColor(.blue)
                        .font(.body.weight(.semibold))
                    }
                    .padding(.bottom)
                    Button {
                        showDeleteSheet.toggle()
                    } label: {
                        Text(NSLocalizedString("delete", comment: "Delete") + " " + NSLocalizedString("song", comment: "Song"))
                            .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            Rectangle()
                                .fill(.clear)
                                .background(Material.regular)
                                .mask { RoundedRectangle(cornerRadius: 20) }
                        }
                        .foregroundColor(.red)
                        .font(.body.weight(.semibold))
                    }
                }
                .padding(.vertical)
            }
            Divider().padding(.horizontal, -16)
            Button {
                songSettingsViewModel.updateSongSettings(songId: song.id ?? "", duration: "\(minutes):\(seconds < 10 ? "0" + String(seconds) : String(seconds))") { success in
                    if success {
                        
                    } else {
                        print("Error saving song settings")
                    }
                }
                self.autoscrollDuration = "\(minutes):\(seconds < 10 ? "0" + String(seconds) : String(seconds))"
                presMode.wrappedValue.dismiss()
            } label: {
                Text(NSLocalizedString("save", comment: "Save"))
                    .frame(maxWidth: .infinity)
                    .modifier(NavButtonViewModifier())
            }
            .padding(.top)
        }
        .padding()
        .onAppear {
            songSettingsViewModel.fetchSong(songId: song.id ?? "") { song in
                self.autoscrollDuration = song.autoscrollDuration ?? song.duration ?? ""
            }
            
            let totalSeconds = durationStringToSeconds(autoscrollDuration)
            minutes = Int(totalSeconds / 60)
            seconds = Int(totalSeconds) % 60
        }
        .confirmationDialog("Delete Song", isPresented: $showDeleteSheet) {
            Button("Delete", role: .destructive) {
                if let folder = folder {
                    songViewModel.moveSongToRecentlyDeleted(folder, song)
                } else {
                    songViewModel.moveSongToRecentlyDeleted(song)
                }
                hasDeletedSong = true
                presMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(song.title)\"?")
        }
    }
}

#Preview {
    SongSettingsView(song: Song.song, autoscrollDuration: .constant("3:20"), hasDeletedSong: .constant(true))
}
