//
//  Message.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 28. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

struct JSLocationMessage: Codable, Sendable {

    let id: Double
    let command: Command
    let options: Options?
}

extension JSLocationMessage {

    enum Command: String, Codable {
        case getCurrentPosition, watchPosition, clearWatch
    }
}

extension JSLocationMessage {

    struct Options: Codable {

        let maximumAge: Double?
        let timeout: Double?
        let enableHighAccuracy: Bool?
    }
}
