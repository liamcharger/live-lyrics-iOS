//
//  BandService.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct BandService {
    func fetchBand(fromCode joinCode: String, completion: @escaping (Band?) -> Void) {
        Firestore.firestore().collection("bands").whereField("joinId", isEqualTo: joinCode).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching band: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(nil)
                return
            }
            
            let bands = documents.compactMap { document in
                try? document.data(as: Band.self)
            }
            
            completion(bands.first)
        }
    }
    
    func fetchUserBands(forUid: String? = nil, completion: @escaping([Band]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("bands").whereField("members", arrayContains: uid).addSnapshotListener { snapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            let bands = documents.compactMap({ try? $0.data(as: Band.self) })
            
            completion(bands)
        }
    }
    
    func fetchBands(completion: @escaping([Band]) -> Void) {
        Firestore.firestore().collection("bands").addSnapshotListener { snapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            let bands = documents.compactMap({ try? $0.data(as: Band.self) })
            
            completion(bands)
        }
    }
    
    func fetchBandMembers(band: Band, completion: @escaping([BandMember]) -> Void) {
        Firestore.firestore().collection("bands").document(band.id!).collection("members").addSnapshotListener { snapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            let members = documents.compactMap({ try? $0.data(as: BandMember.self) })
            
            completion(members)
        }
    }
    
    func fetchMemberRoles(band: Band, completion: @escaping([BandRole]) -> Void) {
        Firestore.firestore().collection("bands").document(band.id!).collection("roles").addSnapshotListener { snapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            let roles = documents.compactMap({ try? $0.data(as: BandRole.self) })
            
            completion(roles)
        }
    }
    
    func createBand(name: String, completion: @escaping() -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let user = AuthViewModel.shared.currentUser else { return }
        
        let id = UUID().uuidString
        
        Firestore.firestore().collection("bands").document(id).setData(["name": name, "createdBy": uid, "joinId": generateBandJoinCode(), "admins": FieldValue.arrayUnion([uid]), "members": FieldValue.arrayUnion([uid])]) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            createBandMember(from: user, admin: true, bandId: id) {
                completion()
            }
        }
    }
    
    func createBandMember(from user: User, admin: Bool, bandId: String, role: BandRole? = nil, completion: @escaping() -> Void) {
        let member: [String: Any?] = [
            "uid": user.id!,
            "fullname": user.fullname,
            "username": user.username,
            "role": role?.name,
            "roleColor": role?.color,
            "roleIcon": role?.icon
        ]
        Firestore.firestore().collection("bands").document(bandId).collection("members").document(user.id!).setData(member) { error in
            if let error = error {
                print(error.localizedDescription)
            }
            completion()
        }
    }
    
    func leaveBand(band: Band, userUid: String? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("bands").document(band.id!).updateData(["members": FieldValue.arrayRemove([userUid ?? uid])]) { error in
            if let error = error {
                print(error.localizedDescription)
            }
            Firestore.firestore().collection("bands").document(band.id!).collection("members").document(userUid ?? uid).delete { error in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func deleteBand(band: Band) {
        Firestore.firestore().collection("bands").document(band.id!).delete { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    func joinBand(band: Band, admin: Bool? = nil, completion: @escaping() -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let user = AuthViewModel.shared.currentUser else { return }
        
        Firestore.firestore().collection("bands").document(band.id!).updateData(["members": FieldValue.arrayUnion([uid])]) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            createBandMember(from: user, admin: admin ?? false, bandId: band.id!) {
                completion()
            }
        }
    }
    
    func saveRole(member: BandMember, band: Band, role: BandRole?, completion: @escaping () -> Void) {
        guard let bandId = band.id, let memberId = member.id else { return }
        let ref = Firestore.firestore().collection("bands").document(bandId).collection("members").document(memberId)
        
        print(role?.id ?? "No role ID")
        if let roleId = role?.id {
            ref.updateData(["roleId": roleId]) { error in
                if let error = error {
                    print(error.localizedDescription)
                }
                completion()
            }
        } else {
            ref.updateData(["roleId": FieldValue.delete()]) { error in
                if let error = error {
                    print(error.localizedDescription)
                }
                completion()
            }
        }
    }
    
    func generateBandJoinCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var code = ""
        for _ in 0..<6 {
            let randomIndex = Int.random(in: 0..<characters.count)
            let char = characters[characters.index(characters.startIndex, offsetBy: randomIndex)]
            code.append(char)
        }
        return code
    }
}
