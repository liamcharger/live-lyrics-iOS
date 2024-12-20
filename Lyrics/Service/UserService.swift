//
//  UserService.swift
//  Touchbase
//
//  Created by Liam Willey on 3/6/23.
//

import Foundation
import FirebaseFunctions
import FirebaseFirestore
import FirebaseAuth
import Firebase

struct UserService {
    func changePassword(password: String, currentPassword: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        let user = Auth.auth().currentUser
        
        let credential = EmailAuthProvider.credential(withEmail: user!.email!, password: currentPassword)
        
        user?.reauthenticate(with: credential, completion: { authResult, error in
            if let error = error {
                completionBool(false)
                completionString(error.localizedDescription)
                // Handle re-authentication error
                return
            }
            user?.updatePassword(to: password, completion: { error in
                if let error = error {
                    completionBool(false)
                    completionString(error.localizedDescription)
                    // Handle password update error
                    return
                }
                
                Firestore.firestore().collection("users").document(user!.uid)
                    .updateData(["password": password]) {
                        error in
                        if let error = error {
                            completionBool(false)
                            completionString(error.localizedDescription)
                            return
                        }
                        completionBool(true)
                    }
            })
        })
    }
    
    func updateSettings(_ user: User, wordCount: Bool, data: String, wordCountStyle: String, showsExplicitSongs: Bool, metronomeStyle: [String], completion: @escaping(Bool, String) -> Void) {
        Firestore.firestore().collection("users").document(user.id!)
            .updateData(["wordCount": wordCount, "showDataUnderSong": data, "wordCountStyle": wordCountStyle, "showsExplicitSongs": showsExplicitSongs, "metronomeStyle": metronomeStyle]) {
                error in
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                completion(true, "")
            }
    }
    
    func fetchUser(withUid uid: String, completion: @escaping(User) -> Void) {
        Firestore.firestore().collection("users")
            .document(uid)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                guard let user = try? snapshot.data(as: User.self) else { return }
                completion(user)
            }
    }
    
    func fetchUsers(withUids uids: [String], completion: @escaping([User]) -> Void) {
        let group = DispatchGroup()
        var users = [User]()
        
        for uid in uids {
            group.enter()
            Firestore.firestore().collection("users")
                .document(uid)
                .getDocument { snapshot, error in
                    guard let snapshot = snapshot else { return }
                    guard let user = try? snapshot.data(as: User.self) else { return }
                    
                    users.append(user)
                    
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
            completion(users)
        }
    }
    
    func fetchUsers(withUsername username: String, filterCurrentUser: Bool, completion: @escaping([User]) -> Void) {
        Firestore.firestore().collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            let users = documents.compactMap({ try? $0.data(as: User.self) }).filter { user in
                if !filterCurrentUser {
                    return false
                } else {
                    if user.id ?? "" != Auth.auth().currentUser?.uid {
                        return true
                    }
                }
                return false
            }
            completion(users)
        }
    }
    
    func updateFCMId(_ user: User, id: String) {
        Firestore.firestore().collection("users").document(user.id!)
            .updateData(["fcmId": id]) {
                error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
            }
    }
    
    func sendNotificationToFCM(tokens: [String], title: String, body: String, type: NotificationType) {
        var data: [String: Any] = [
            "tokens": tokens,
            "title": title,
            "body": body
        ]
        
        if type == .incoming {
            data["deep_link"] = "live-lyrics://share-invites"
        } else if type == .accepted {
            data["deep_link"] = "live-lyrics://profile"
        } else if type == .declined {
            data["deep_link"] = "live-lyrics://profile"
        } else if type == .left {
            data["deep_link"] = "live-lyrics://profile"
        }
        
        Functions.functions().httpsCallable("sendNotification").call(data) { result, error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            } else {
                print("Notification sent successfully")
            }
        }
    }
}

enum NotificationType {
    case incoming
    case accepted
    case declined
    case left
}
