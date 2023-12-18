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
    
    init(song: Song) {
        self.fetchNotesForInit(song: song)
    }
    
    let service = SongService()
    
    func updateNotes(_ song: Song, notes: String) {
        service.updateNotes(song: song, notes: notes)
    }
    
    func fetchNotes(_ song: Song, completion: @escaping(String) -> Void) {
        service.fetchNotes(song: song) { notes in
            completion(notes)
            self.isLoading = false
        }
    }
    
    func fetchNotesForInit(song: Song) {
        fetchNotes(song) { notes in
            self.notes = notes
            self.isLoading = false
        }
    }
}
