//
//  MultipeerConnectivityManager.swift
//  Lyrics
//
//  Created by Liam Willey on 9/25/24.
//

import MultipeerConnectivity
import SwiftUI

class MultipeerConnectivityManager: NSObject, ObservableObject {
    let serviceType = "livelyrics-st"
    
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    @Published var peers: [MCPeerID] = []
    @Published var isAdvertising: Bool = false
    @Published var isConnected: Bool = false
    @Published var transactionCompleted: Bool = false
    
    static let shared = MultipeerConnectivityManager()
    
    override init() {
        super.init()
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }
    
    func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        isAdvertising = true
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        isAdvertising = false
    }
    
    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
    }
    
    func invitePeer(_ peerID: MCPeerID) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 60)
    }
}

extension MultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept for simplicity
        invitationHandler(true, session)
    }
}

extension MultipeerConnectivityManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        peers.append(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        peers.removeAll(where: { $0 == peerID })
    }
}

extension MultipeerConnectivityManager: MCSessionDelegate {
    func sendData(_ data: MultipeerInvitation) {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(data) {
            try? session.send(encodedData, toPeers: session.connectedPeers, with: .reliable)
            self.transactionCompleted = true
        }
    }
    
    // TODO: add recipient response to toggle transactionCompleted bool for a more synced experience
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let decoder = JSONDecoder()
        if let receivedData = try? decoder.decode(MultipeerInvitation.self, from: data) {
            print(receivedData)
            BandsViewModel.shared.joinBand(receivedData.contentId) { success in
                self.transactionCompleted = true
                if !success {
                    // Show error message to user
                }
            }
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.isConnected = state == .connected
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
