import FirebaseFirestoreSwift

struct LocalUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var username: String
    var fullname: String
    var password: String?
    var wordCount: Bool?
    var showDataUnderSong: String?
    var wordCountStyle: String?
    var hasSubscription: Bool?
    var hasCollapsedPremium: Bool?
    var currentVersion: String?
    var showsExplicitSongs: Bool?
    var songs: [Song]
    var folders: [LocalFolder]
    var recentlyDeletedSongs: [RecentlyDeletedSong]
}
