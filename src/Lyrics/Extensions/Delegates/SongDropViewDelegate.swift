//
//  SongDropViewDelegate.swift
//  Lyrics
//
//  Created by Liam Willey on 1/22/24.
//

import Foundation
import SwiftUI

//struct SongDropViewDelegate: DropDelegate {
//    let destinationItem: Song
//    @Binding var items: [Song]
//    @Binding var draggedItem: Song?
//    
//    @ObservedObject var authViewModel: AuthViewModel
//    @ObservedObject var mainViewModel = MainViewModel.shared
//    
//    func dropUpdated(info: DropInfo) -> DropProposal? {
//        return DropProposal(operation: .move)
//    }
//    
//    func performDrop(info: DropInfo) -> Bool {
//        self.draggedItem = nil
//        self.mainViewModel.songs = items
//        self.mainViewModel.updateSongOrder()
//        return true
//    }
//    
//    func dropEntered(info: DropInfo) {
//        if let draggedItem {
//            let fromIndex = items.firstIndex(of: draggedItem)
//            if let fromIndex {
//                let toIndex = items.firstIndex(of: destinationItem)
//                if let toIndex, fromIndex != toIndex {
//                    withAnimation {
//                        self.items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
//                    }
//                }
//            }
//        }
//    }
//}
