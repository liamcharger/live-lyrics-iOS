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
    
    let service = BandService()
    
    static let shared = BandsViewModel()
    
    func fetchUserBands() {
        service.fetchUserBands { bands in
            self.isLoadingUserBands = false
            self.userBands = bands
        }
    }
    
    func fetchBands() {
        service.fetchBands { bands in
            self.isLoadingBands = false
            self.bands = bands
        }
    }
    
    func fetchBandMembers(_ band: Band, completion: @escaping([BandMember]) -> Void) {
        service.fetchBandMembers(band: band) { members in
            completion(members)
        }
    }
    
    func createBand(_ name: String, completion: @escaping() -> Void) {
        self.isCreatingBand = true
        service.createBand(name: name) {
            self.isCreatingBand = false
            completion()
        }
    }
    
    func joinBand(_ code: String, completion: @escaping() -> Void) {
        service.fetchBand(fromCode: code) { band in
            if let band = band {
                self.service.joinBand(band: band) {
                    completion()
                }
            } else {
                // Error...
            }
        }
    }
    
    func leaveBand(_ band: Band, uid: String? = nil) {
        service.leaveBand(band: band, userUid: uid)
    }
    
    func deleteBand(_ band: Band) {
        service.deleteBand(band: band)
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
