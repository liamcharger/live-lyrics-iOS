//
//  User.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var username: String
    var fullname: String
    var password: String?
    var wordCount: Bool?
    var showDataUnderSong: String?
    var wordCountStyle: String?
    var showAds: Bool?
    var hasPro: Bool?
    var currentVersion: String?
    var showsExplicitSongs: Bool?
    var metronomeStyle: [String]?
    var fcmId: String?
    var purchaseReceipt: String?
}
