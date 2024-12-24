//
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
/// A structure that represents options for configuring location-related commands.
///
/// These parameters correspond to options available in the Geolocation API of web browsers,
/// providing additional configurations necessary for executing location-related commands.
public struct JSLocationMessageOptions: Codable, Sendable {

    /// The maximum age in milliseconds of a cached position that is acceptable to return.
    /// If the cached position is older than the specified `maximumAge`, the location will be re-fetched.
    /// A value of 0 indicates that no cached position should be used and a new position should be obtained.
    /// If not provided, there is no limit on the maximum age of cached position.
    public let maximumAge: Double?

    /// The maximum time in milliseconds allowed for a location fetch operation to complete.
    /// If the timeout is reached before a position is found, the operation fails.
    /// If not provided, the location fetch can take an indefinite amount of time.
    public let timeout: Double?

    /// A Boolean value indicating whether the location service should use the most accurate method
    /// available to determine the position of the device.
    /// Enabling high accuracy may use more battery power and take longer, but provides more precise results.
    /// Defaults to `false` if not provided.
    public let enableHighAccuracy: Bool?
}
