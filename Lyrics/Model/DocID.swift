//
//  DocID.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import SwiftUI

struct DocID: Identifiable, Codable {
    @DocumentID var id: String?
    var order: Int
    var folderId: String?
}
