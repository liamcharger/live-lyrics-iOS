//
//  DocID.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import Foundation
import FirebaseFirestoreSwift
import SwiftUI

struct SystemDoc: Identifiable, Codable {
    @DocumentID var id: String?
    var isDisplayed: Bool?
    var title: String?
    var subtitle: String?
    var imageName: String?
    var buttonText: String?
}
