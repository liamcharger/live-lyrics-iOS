//
//  NotesViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 6/28/23.
//

import Foundation

class NotesViewModel: ObservableObject {
    @Published var notes: String = ""
    @Published var isLoading = true
    
    let service = SongService()
    
    static let shared = NotesViewModel()
    
    func updateNotes(song: Song? = nil, folder: Folder? = nil, notes: String) {
        DispatchQueue.main.async {
            if let song = song {
                self.service.updateNotes(song: song, notes: notes)
            } else if let folder = folder {
                self.service.updateNotes(folder: folder, notes: notes)
            }
        }
    }
    
    func fetchNotes(song: Song? = nil, folder: Folder? = nil) {
        DispatchQueue.main.async {
            if let song = song {
                self.service.fetchNotes(song: song) { notes in
                    self.notes = notes
                }
            } else if let folder = folder {
                self.service.fetchNotes(folder: folder) { notes in
                    self.notes = notes
                }
            }
            self.isLoading = false
        }
    }
}
