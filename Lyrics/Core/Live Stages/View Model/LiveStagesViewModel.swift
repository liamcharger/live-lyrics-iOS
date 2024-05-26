//
//  LiveStagesViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 5/26/24.
//

import Foundation

class LiveStagesViewModel: ObservableObject {
    static let shared = LiveStagesViewModel()
    
    @Published var isConnectedToStage = false
}
