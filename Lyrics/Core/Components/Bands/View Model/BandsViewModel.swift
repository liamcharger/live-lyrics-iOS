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
    @Published var isLoadingBands = true
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
    
    func fetchUserBands(completion: @escaping() -> Void) {
        service.fetchUserBands { bands in
            self.isLoadingUserBands = false
            self.userBands = bands
            completion()
        }
    }
    
    func fetchBands() {
        service.fetchBands { bands in
            self.isLoadingBands = false
            self.bands = bands
        }
    }
    
    func fetchBandMembers(_ band: Band, withListener: Bool = true, completion: @escaping([BandMember]) -> Void) {
        service.fetchBandMembers(band: band, withListener: withListener) { members in
            completion(members)
        }
    }
    
    func fetchMemberRoles(_ band: Band, completion: @escaping([BandRole]) -> Void) {
        completion(memberRoles)
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
    
    func joinBand(_ code: String, completion: @escaping(Bool) -> Void) {
        service.fetchBand(fromCode: code) { band in
            if let band = band {
                self.service.joinBand(band: band) {
                    completion(true)
                }
            } else {
                completion(false)
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
}
