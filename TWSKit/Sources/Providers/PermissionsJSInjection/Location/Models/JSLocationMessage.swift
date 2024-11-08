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
    let options: JSLocationMessageOptions?
}

extension JSLocationMessage {

    enum Command: String, Codable {
        case getCurrentPosition, watchPosition, clearWatch
    }
}

// periphery:ignore - may be used by the client of our SDK
/// These parameters correspond to options available in the Geolocation API of web browsers,
/// providing additional configurations necessary for executing location-related commands.
struct JSLocationMessageOptions: Codable, Sendable {

    /// The maximum age in milliseconds of a cached position that is acceptable to return.
    /// If the cached position is older than the specified `maximumAge`, the location will be re-fetched.
    /// A value of 0 indicates that no cached position should be used and a new position should be obtained.
    /// If not provided, there is no limit on the maximum age of cached position.
    let maximumAge: Double?

    /// The maximum time in milliseconds allowed for a location fetch operation to complete.
    /// If the timeout is reached before a position is found, the operation fails.
    /// If not provided, the location fetch can take an indefinite amount of time.
    let timeout: Double?

    /// A Boolean value indicating whether the location service should use the most accurate method
    /// available to determine the position of the device.
    /// Enabling high accuracy may use more battery power and take longer, but provides more precise results.
    /// Defaults to `false` if not provided.
    let enableHighAccuracy: Bool?
}
