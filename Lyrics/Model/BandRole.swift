//
//  BandRole.swift
//  Lyrics
//
//  Created by Liam Willey on 7/2/24.
//

import Foundation
import FirebaseFirestoreSwift

struct BandRole: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let name: String
    let icon: String?
    let color: String?
    
    func rhs(_ rhs: BandRole) -> Bool {
        id == rhs.id
    }
}
