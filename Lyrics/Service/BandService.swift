//
//  BandService.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import Foundation
import FirebaseFirestore

struct BandService {
    func fetchUserBands() {
        Firestore.firestore().collection("bands").whereField("", isEqualTo: "").addSnapshotListener { snapshot, error in
            
        }
    }
    
    func fetchBands() {
        
    }
}
