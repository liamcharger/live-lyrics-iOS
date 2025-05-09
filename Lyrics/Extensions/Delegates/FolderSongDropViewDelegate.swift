//
//  FolderSongDropViewDelegate.swift
//  Lyrics
//
//  Created by Liam Willey on 4/12/24.
//

import Foundation
import SwiftUI

struct FolderSongDropViewDelegate: DropDelegate {
    let folder: Folder
    let destinationItem: Song
    @Binding var items: [Song]
    @Binding var draggedItem: Song?
    
    @ObservedObject var mainViewModel = MainViewModel.shared
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        self.draggedItem = nil
        self.mainViewModel.updateSongOrder(folder, updatedList: items)
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        if let draggedItem {
            guard !(draggedItem.pinned ?? false) else { return }
            
            let fromIndex = items.firstIndex(of: draggedItem)
            if let fromIndex {
                let toIndex = items.firstIndex(of: destinationItem)
                if let toIndex, fromIndex != toIndex {
                    withAnimation {
                        self.items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
                    }
                }
            }
        }
    }
}
