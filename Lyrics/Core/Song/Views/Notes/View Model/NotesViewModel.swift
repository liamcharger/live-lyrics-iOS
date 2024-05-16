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
    
    init(song: Song? = nil, folder: Folder? = nil) {
        if let song = song {
            self.fetchNotesForInit(song: song)
        } else if let folder = folder {
            self.fetchNotesForInit(folder: folder)
        }
    }
    
    let service = SongService()
    
    func updateNotes(song: Song? = nil, folder: Folder? = nil, notes: String) {
        DispatchQueue.main.async {
            if let song = song {
                self.service.updateNotes(song: song, notes: notes)
            } else if let folder = folder {
                self.service.updateNotes(folder: folder, notes: notes)
            }
        }
    }
    
    func fetchNotes(song: Song? = nil, folder: Folder? = nil, completion: @escaping(String) -> Void) {
        DispatchQueue.main.async {
            var completedNotes = ""
            
            if let song = song {
                self.service.fetchNotes(song: song) { notes in
                    completedNotes = notes
                }
            } else if let folder = folder {
                self.service.fetchNotes(folder: folder) { notes in
                    completedNotes = notes
                }
            }
            completion(completedNotes)
            self.isLoading = false
        }
    }
    
    func fetchNotesForInit(song: Song) {
        fetchNotes(song: song) { notes in
            self.notes = notes
            self.isLoading = false
        }
    }
    
    func fetchNotesForInit(folder: Folder) {
        fetchNotes(folder: folder) { notes in
            self.notes = notes
            self.isLoading = false
        }
    }
}
