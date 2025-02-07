//
//  BandsViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 7/1/24.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class BandsViewModel: ObservableObject {
    @Published var bands = [Band]()
    @Published var userBands = [Band]()
    @Published var isLoadingUserBands = true
    @Published var isCreatingBand = false
    @Published var isSavingMemberRole = false
    
    let memberRoles: [BandRole] = [
        BandRole(id: "vocalist", name: "Vocalist", icon: "microphone-stand", color: nil),
        BandRole(id: "backup_vocalist", name: "Backup Vocalist", icon: "microphone-stand", color: nil),
        BandRole(id: "lead_guitarist", name: "Lead Guitarist", icon: "guitar", color: nil),
        BandRole(id: "rhythm_guitarist", name: "Rhythm Guitarist", icon: "guitar", color: nil),
        BandRole(id: "bass_guitarist", name: "Bass Guitarist", icon: "guitar-electric", color: nil),
        BandRole(id: "drummer", name: "Drummer", icon: "drum", color: nil),
        BandRole(id: "keyboardist", name: "Keyboardist", icon: "piano-keyboard", color: nil),
    ]
    let service = BandService()
    
    static let shared = BandsViewModel()
    
    func fetchUserBands(withListener: Bool = true, completion: @escaping() -> Void) {
        service.fetchUserBands(withListener: withListener) { bands in
            self.isLoadingUserBands = false
            self.userBands = bands
            completion()
        }
    }
    
    func fetchBandMembers(_ band: Band, withListener: Bool = true, completion: @escaping([BandMember]) -> Void) {
        service.fetchBandMembers(band: band, withListener: withListener) { members in
            completion(members)
        }
    }
    
    func fetchMemberRoles(_ band: Band, completion: @escaping([BandRole]) -> Void) {
        completion(memberRoles)
        
        // TODO: we'll need this function to fetch custom member roles
        /*
         service.fetchMemberRoles(band: band) { roles in
            completion(roles)
        }
         */
    }
    
    func createBand(_ name: String, completion: @escaping() -> Void) {
        self.isCreatingBand = true
        service.createBand(name: name) {
            self.isCreatingBand = false
            completion()
        }
    }
    
    func joinBand(_ code: String, completion: @escaping(String?) -> Void) {
        service.fetchBand(fromCode: code) { band in
            if let band = band {
                if !band.members.contains(uid()) {
                    self.service.joinBand(band: band) {
                        completion(nil)
                    }
                } else {
                    completion(NSLocalizedString("already_joined_band", comment: ""))
                }
            } else {
                completion(NSLocalizedString("band_with_code_not_found", comment: ""))
            }
        }
    }
    
    func leaveBand(_ band: Band, uid: String? = nil) {
        service.leaveBand(band: band, userUid: uid)
    }
    
    func deleteBand(_ band: Band) {
        service.deleteBand(band: band)
    }
    
    func saveRole(to member: BandMember, for band: Band, role: BandRole?) {
        self.isSavingMemberRole = true
        service.saveRole(member: member, band: band, role: role) {
            self.isSavingMemberRole = false
        }
    }
    
    func getRoleColor(_ color: String) -> Color {
        switch color {
        case "red":
            return .red
        case "green":
            return .green
        case "blue":
            return .blue
        case "gray":
            return .gray
        case "orange":
            return .orange
        case "none":
            return .clear
        default:
            return .gray
        }
    }
    
    func bandCreator(_ band: Band) -> Bool {
        return band.createdBy == uid()
    }
    
    func bandAdmin(_ band: Band) -> Bool {
        return band.admins.contains(uid())
    }
}
