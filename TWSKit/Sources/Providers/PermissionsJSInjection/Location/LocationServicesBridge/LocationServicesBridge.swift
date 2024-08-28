//
//  LocationServicesBridge.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 28. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import CoreLocation

/// An location service interface used to communicate between the JavaScript world and the iOS world
public protocol LocationServicesBridge: Actor {

    /// Before calling `getCurrentPosition` or `watchPosition`,
    /// we must first check if the necessary permissions are granted.
    /// If permissions are not granted, we'll need to notify the JavaScript side.
    /// If permissions are in place, we can proceed by either retrieving a single
    /// location or starting continuous location updates.
    func checkPermission() async throws

    /// Get a single, last known location
    /// - Parameters:
    ///   - options: An instance of `JSLocationMessageOptions` that specifies options such as maximum age, timeout, and accuracy for the location updates.
    /// - Returns: The most recent location available, or `nil` if no location data is available.
    func location(
        options: JSLocationMessageOptions?
    ) -> CLLocation?

    /// Begin continuous location updates using the specified ID
    /// - Parameters:
    ///   - id: The unique identifier for the location update session.
    ///   - options: An instance of `JSLocationMessageOptions` that specifies options such as maximum age, timeout, and accuracy for the location updates.
    /// - Returns: An asynchronous stream of `CLLocation` objects representing the device’s location over time.
    func startUpdatingLocation(
        id: Double,
        options: JSLocationMessageOptions?
    ) -> AsyncStream<CLLocation>

    /// Stop continuous location updates associated with the specified ID
    /// - Parameter id: The unique identifier for the location update session to be stopped.
    func stopUpdatingLocation(id: Double)
}
