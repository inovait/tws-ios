//
//  TWSView+NetworkMonitor.swift
//  TWS
//
//  Created by Miha Hozjan on 26. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import Network

@MainActor
@Observable
class NetworkMonitor {

    private var monitor: NWPathMonitor
    private var queue: DispatchQueue

    var isConnected: Bool = true

    init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "NetworkMonitor")
        self.monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = (path.status == .satisfied)
            }
        }
        self.monitor.start(queue: self.queue)
    }
}
