//
//  UserService.swift
//  Touchbase
//
//  Created by Liam Willey on 3/6/23.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import FirebaseAuth
import Firebase

struct UserService {
    func fetchSystemDoc(completion: @escaping (SystemDoc) -> Void) {
        Firestore.firestore().collection("system").document("system-doc")
            .addSnapshotListener { snapshot, error in
                if error != nil {
                    print("Error fetching sys doc...")
                    return
                }
                
                guard let snapshot = snapshot, let doc = try? snapshot.data(as: SystemDoc.self) else {
                    print("Could not parse sys doc...")
                    return
                }
                
                completion(doc)
            }
    }
    
    func changePassword(_ user: User, password: String, currentPassword: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
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
                  // Password update successful
                   Firestore.firestore().collection("users").document(user?.uid ?? "")
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
    
    func updateSettings(_ user: User, wordCount: Bool, data: String, wordCountStyle: String, showsExplicitSongs: Bool, enableAutoscroll: Bool, metronomeStyle: [String], completion: @escaping(Bool, String) -> Void) {
        Firestore.firestore().collection("users").document(user.id ?? "")
            .updateData(["wordCount": wordCount, "showDataUnderSong": data, "wordCountStyle": wordCountStyle, "showsExplicitSongs": showsExplicitSongs, "enableAutoscroll": enableAutoscroll, "metronomeStyle": metronomeStyle]) {
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
    
    func fetchUsers(completion: @escaping([User]) -> Void) {
        Firestore.firestore().collection("users").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            let users = documents.compactMap({ try? $0.data(as: User.self) })
            completion(users)
        }
    }
}
