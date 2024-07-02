//
//  BandService.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct BandService {
    func fetchUserBands(forUid: String? = nil, completion: @escaping([Band]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("bands").whereField("joinedUsers", arrayContains: uid).addSnapshotListener { snapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            let bands = documents.compactMap({ try? $0.data(as: Band.self) })
            
            completion(bands)
        }
    }
    
    func fetchBands(completion: @escaping([Band]) -> Void) {
        Firestore.firestore().collection("bands").addSnapshotListener { snapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            let bands = documents.compactMap({ try? $0.data(as: Band.self) })
            
            completion(bands)
        }
    }
}
