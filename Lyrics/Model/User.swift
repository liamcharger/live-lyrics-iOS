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
    var hasSubscription: Bool?
    var showAds: Bool?
    var hasCollapsedPremium: Bool?
    var currentVersion: String?
    var showsExplicitSongs: Bool?
    var enableAutoscroll: Bool?
    var isLocal: Bool?
}
