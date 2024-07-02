//
//  BandsViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import Foundation
import FirebaseFirestore

class BandsViewModel: ObservableObject {
    @Published var bands = [Band]()
    @Published var userBands = [Band]()
    @Published var isLoadingUserBands = true
    @Published var isLoadingBands = true
    
    let service = BandService()
    
    static let shared = BandsViewModel()
    
    func fetchUserBands() {
        service.fetchUserBands { bands in
            self.isLoadingUserBands = false
            self.userBands = bands
        }
    }
    
    func fetchBands() {
        service.fetchBands { bands in
            self.isLoadingBands = false
            self.bands = bands
        }
    }
}
