//
//  Message.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 28. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

struct Message: Codable, Sendable {

    let id: Double
    let command: Command
    let options: Options?
}

extension Message {

    enum Command: String, Codable {
        case getCurrentPosition, watchPosition, clearWatch
    }
}

extension Message {

    struct Options: Codable {

        let maximumAge: Double?
        let timeout: Double?
        let enableHighAccuracy: Bool?
    }
}
