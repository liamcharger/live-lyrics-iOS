//
//  NetworkManager.swift
//  Touchbase
//
//  Created by Liam Willey on 3/31/23.
//

import Foundation
import Network

class NetworkManager: ObservableObject {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "NetworkManager")
    @Published var isConnected = false

    init() {
        checkStatus()
    }

    func checkStatus() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}

