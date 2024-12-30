//
//  NotesViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 6/28/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class NotesViewModel: ObservableObject {
    @Published var notes: String = ""
    @Published var isLoading = true
    @Published var lastUpdatedNotes: String = ""
    
    @State private var updatedNotesTimer: Timer?
    
    var listener: ListenerRegistration? = nil
    
    let service = SongService()
    
    static let shared = NotesViewModel()
    
    func stopUpdatingNotes() {
        self.updatedNotesTimer?.invalidate()
        self.updatedNotesTimer = nil
        
        self.listener?.remove()
    }
    
    func updateNotes(song: Song? = nil, folder: Folder? = nil, notes: String) {
        DispatchQueue.main.async {
            if self.notes != self.lastUpdatedNotes {
                if let song = song {
                    self.service.updateNotes(song: song, notes: notes)
                } else if let folder = folder {
                    self.service.updateNotes(folder: folder, notes: notes)
                }
                
                self.lastUpdatedNotes = notes
            }
        }
    }
    
    // FIXME: we aren't using this timer (we're using .onDisappear for now) because it's not being cancelled when it should be, causing multiple bugs
    func startUpdatingNotes(song: Song? = nil, folder: Folder? = nil) {
        self.updatedNotesTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            if self.notes != self.lastUpdatedNotes {
                self.updateNotes(song: song, folder: folder, notes: self.notes)
            }
        }
    }
    
    func fetchNotes(song: Song? = nil, folder: Folder? = nil) {
        self.isLoading = true
        
        DispatchQueue.main.async {
            if let song = song {
                self.listener = self.service.fetchNotes(song: song) { notes in
                    self.notes = notes
                    self.lastUpdatedNotes = notes
                    self.isLoading = false
                }
            } else if let folder = folder {
                self.listener = self.service.fetchNotes(folder: folder) { notes in
                    self.notes = notes
                    self.lastUpdatedNotes = notes
                    self.isLoading = false
                }
            }
        }
    }
}
