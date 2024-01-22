//
//  FolderDropViewDelegate.swift
//  Lyrics
//
//  Created by Liam Willey on 1/22/24.
//

import Foundation
import SwiftUI

struct FolderDropViewDelegate: DropDelegate {
    let destinationItem: Folder
    @Binding var items: [Folder]
    @Binding var draggedItem: Folder?
    
    @ObservedObject var mainViewModel = MainViewModel()
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        self.mainViewModel.folders = items
        self.mainViewModel.updateFolderOrder()
        return true
    }
    
    func dropEntered(info: DropInfo) {
        if let draggedItem {
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
