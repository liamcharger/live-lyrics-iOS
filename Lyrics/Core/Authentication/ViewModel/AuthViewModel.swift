//
//  AuthViewModel.swift
//  Touchbase
//
//  Created by Liam Willey on 2/24/23.
//

import FirebaseAuth
import Firebase
import FirebaseFirestore
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var userSession: FirebaseAuth.User?
    @Published var didAuthenticateUser = false
    @Published var isLoadingUsers = false
    @Published var currentUser: User?
    @Published var uniqueUserID: String = ""
    
    @AppStorage("fullname") var fullname: String?
    
    private var tempUserSession: FirebaseAuth.User?
    private let service = UserService()
    private let songService = SongService()
    
    let error_deleting_account_string = "There was an error deleting your account"
    
    static let shared = AuthViewModel()
    
    init() {
        self.userSession = Auth.auth().currentUser
        self.fetchUser()
        self.updateAppStatus()
    }
    
    func updateAppStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid).updateData(["currentVersion" : NotificationManager.shared.getCurrentAppVersion()]) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func login(withEmail email: String, password: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Error logging in user: \(error.localizedDescription)")
                completionBool(false)
                completionString(error.localizedDescription)
                return
            }
            
            guard let user = result?.user else { return }
            self.userSession = user
            self.fetchUser()
            
            MainViewModel.shared.notifications = []
            MainViewModel.shared.saveNotificationToUserDefaults()
            
            completionBool(true)
        }
    }
    
    func register(withEmail email: String, password: String, username: String, fullname: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Error registering user: \(error.localizedDescription)")
                completionBool(false)
                completionString(error.localizedDescription)
                return
            }
            
            guard let user = result?.user else { return }
            self.tempUserSession = user
            
            let data = ["email": email,
                        "password": password,
                        "username": username.lowercased(),
                        "fullname": fullname]
            
            Firestore.firestore().collection("users").document(user.uid)
                .setData(data) { _ in
                    self.didAuthenticateUser = true
                    self.userSession = self.tempUserSession
                    self.fetchUser()
                    completionBool(true)
                }
        }
    }
    
    func updateUser(email: String, username: String, fullname: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        self.userSession?.updateEmail(to: email) { error in
            if let error = error {
                completionBool(false)
                completionString(error.localizedDescription)
                return
            }
            
            guard let user = self.userSession else { return }
            
            let data = ["email": email,
                        "username": username.lowercased(),
                        "fullname": fullname]
            
            Firestore.firestore().collection("users").document(user.uid)
                .updateData(data) { _ in
                    self.fetchUser()
                    completionBool(true)
            }
        }
    }
    
    func deleteUser(completion: @escaping(Bool, String) -> Void) {
        let user = userSession
        
        user?.delete { error in
            if let error = error {
                completion(true, self.error_deleting_account_string)
                print(error.localizedDescription)
                return
            }
            Firestore.firestore().collection("users").document(self.currentUser?.id ?? "").delete { error in
                if let error = error {
                    completion(true, self.error_deleting_account_string)
                    print(error.localizedDescription)
                    return
                }
            }
            completion(false, "Success")
        }
        self.signOut()
    }
    
    func fetchUser() {
        guard let uid = userSession?.uid else { return }
        
        service.fetchUser(withUid: uid) { user in
            self.currentUser = user
            self.fullname = user.fullname
            self.uniqueUserID = user.id!.prefix(4).uppercased()
        }
    }
    
    func fetchUsers(uids: [String], completion: @escaping([User]) -> Void) {
        service.fetchUsers(withUids: uids) { users in
            completion(users)
        }
    }
    
    func signOut() {
        self.userSession = nil
        try? Auth.auth().signOut()
    }
    
    func showAds(_ showAds: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if (currentUser?.showAds ?? true) != showAds {
            Firestore.firestore().collection("users").document(uid).updateData(["showAds": showAds]) { error in
                if let error = error {
                    print("Error:", error.localizedDescription)
                }
            }
        }
    }
    
    func updateProStatus(_ hasPro: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if (currentUser?.hasPro ?? false) != hasPro {
            Firestore.firestore().collection("users").document(uid).updateData(["hasPro": hasPro]) { error in
                if let error = error {
                    print("Error:", error.localizedDescription)
                }
            }
        }
    }
    
    func resetPassword(email: String, completion: @escaping(Bool, String) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            completion(true, "Success!")
        }
    }
    
    func fetchUsers(username: String, filterCurrentUser: Bool, completion: @escaping() -> Void) {
        self.isLoadingUsers = true
        service.fetchUsers(withUsername: username, filterCurrentUser: filterCurrentUser) { users in
            self.users = users
            self.isLoadingUsers = false
            completion()
        }
    }
    
    func updateFCMId(_ user: User, id: String) {
        service.updateFCMId(user, id: id)
    }
    
    func sendInviteToUser(request: ShareRequest, users: [ShareUser], includeDefault: Bool, completion: @escaping(Error?) -> Void) {
        songService.sendInviteToUser(request: request, users: users, includeDefault: includeDefault) { error in
            completion(error)
        }
    }
    
    func saveReceiptToFirestore(_ receipt: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid).updateData(["purchaseReceipt": receipt]) { error in
            if let error = error {
                print("Error:", error.localizedDescription)
            }
        }
    }
}
