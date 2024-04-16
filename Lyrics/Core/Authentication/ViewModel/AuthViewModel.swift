//
//  AuthViewModel.swift
//  Touchbase
//
//  Created by Liam Willey on 2/24/23.
//

import FirebaseAuth
import Firebase
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var userSession: FirebaseAuth.User?
    @Published var didAuthenticateUser = false
    @Published var isLoadingUsers = false
    @Published var currentUser: User?
    
    private var tempUserSession: FirebaseAuth.User?
    private let service = UserService()
    private let songService = SongService()
    
    static let shared = AuthViewModel()
    
    init() {
        self.userSession = Auth.auth().currentUser
        self.fetchUser()
        self.updateAppStatus()
    }
    
    func updateAppStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let savedVersion = UserDefaults.standard.string(forKey: "savedVersion")
        
        Firestore.firestore().collection("users").document(uid).updateData(["currentVersion" : savedVersion ?? ""]) { error in
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
            
            print("Logged in user successfully.")
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
            
            print("Registered user successfully.")
            
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
    
    func updateUser(withEmail email: String, username: String, fullname: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
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
                completion(true, NSLocalizedString("error_deleting_account", comment: "There was an error deleting your account"))
                print(error.localizedDescription)
                return
            }
            Firestore.firestore().collection("users").document(self.currentUser?.id ?? "").delete { error in
                if let error = error {
                    completion(true, NSLocalizedString("error_deleting_account", comment: "There was an error deleting your account"))
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
        }
    }
    
    func signOut() {
        self.userSession = nil
        try? Auth.auth().signOut()
    }
    
    func removeAds(showAds: Bool, completion: @escaping(Bool, String) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).updateData(["showAds": showAds]) { error in
            if let error = error {
                print("Error:", error.localizedDescription)
                completion(false, error.localizedDescription)
                return
            }
            completion(true, "Success!")
        }
    }
    
    func updateLocalStatus(localStatus: Bool, completion: @escaping(Bool, String) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).updateData(["isLocal": localStatus]) { error in
            if let error = error {
                print("Error:", error.localizedDescription)
                completion(false, error.localizedDescription)
                return
            }
            completion(true, "Success!")
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
    
    func fetchUsers(username: String) {
        self.isLoadingUsers = true
        service.fetchUsers(withUsername: username) { users in
            self.users = users
            self.isLoadingUsers = false
        }
    }
    
    func updateFCMId(_ user: User, id: String) {
        service.updateFCMId(user, id: id)
    }
    
    func sendInviteToUser(request: ShareRequest, completion: @escaping(Error?) -> Void) {
        songService.sendInviteToUser(request: request) { error in
            completion(error)
        }
    }
}
