//
//  NetworkManager.swift
//  Touchbase
//
//  Created by Liam Willey on 3/31/23.
//

import Foundation
import Network

class NetworkManager {
    static let shared = NetworkManager()
    
    private let monitor = NWPathMonitor()
    private var connected = true
    
    init() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.connected = true
            } else {
                self.connected = false
            }
        }
        
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
    func getNetworkState() -> Bool {
        return connected
    }
}

