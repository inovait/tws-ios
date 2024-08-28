//
//  LocationServicesManager.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 28. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import CoreLocation
import SwiftUI

// Define an actor class that handles location services and acts as a bridge to your application's logic.
public actor TWSDefaultLocationServicesManager: NSObject, LocationServicesBridge, Observable, CLLocationManagerDelegate {

    // MARK: - Properties

    // The CLLocationManager instance responsible for managing location services.
    private let locationManager: CLLocationManager

    // Continuation for asynchronously streaming location updates.
    private var continuations: [Double: AsyncStream<CLLocation>.Continuation?] = [:]

    // Continuation for handling permission requests asynchronously.
    private var authorizationContinuation: CheckedContinuation<Void, Error>?

    // Keep track of requests
    private var requests = Set<Double>()

    // MARK: - Initializer

    /// Initializes a new instance of DefaultLocationServicesBridge.
    /// - Parameter locationManager: A custom CLLocationManager instance, defaulting to a new instance if not provided.
    public init(
        locationManager: CLLocationManager = .init()
    ) {
        self.locationManager = locationManager
        super.init()

        // Set the location manager's delegate to self.
        self.locationManager.delegate = self
    }

    // MARK: - LocationServicesBridge Protocol Conformance

    /// Checks and requests location permissions as needed.
    /// Throws an error if the user denies or restricts access to location services.
    public func checkPermission() async throws {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            // If permission status is not determined, request permission asynchronously.
            try await withCheckedThrowingContinuation { continuation in
                Task {
                    askForPermission(authorizationContinuation: continuation)
                }
            }

        case .restricted, .denied:
            // If permission is restricted or denied, throw an error.
            throw LocationServicesError.denied

        case .authorizedAlways, .authorizedWhenInUse:
            // If permission is granted, do nothing and proceed.
            break

        @unknown default:
            // Handle any future cases that might be added to the authorization status enum.
            break
        }
    }

    /// Retrieves the most recent known location.
    /// - Parameters:
    ///   - options: An instance of `JSLocationMessageOptions` that specifies options such as maximum age, timeout, and accuracy for the location updates.
    /// - Returns: The last known location, or `nil` if no location is available.
    public func location(options _: JSLocationMessageOptions?) -> CLLocation? {
        return locationManager.location // TODO:
        // TODO: on dissapear
    }

    /// Begins streaming continuous location updates.
    /// - Parameters:
    ///   - id: A unique identifier for the location update session
    ///   - options: An instance of `JSLocationMessageOptions` that specifies options such as maximum age, timeout, and accuracy for the location updates.
    /// - Returns: An `AsyncStream` that yields `CLLocation` objects as the device's location updates.
    public func startUpdatingLocation(id: Double, options _: JSLocationMessageOptions?) -> AsyncStream<CLLocation> {
        let stream = AsyncStream<CLLocation>.makeStream()
        continuations[id] = stream.continuation
        locationManager.startUpdatingLocation()
        requests.insert(id)
        return stream.stream
    }

    /// Stops the continuous location updates associated with the specified session ID.
    /// - Parameter id: The unique identifier for the location update session to stop.
    public func stopUpdatingLocation(id: Double) {
        continuations[id]??.finish()
        continuations[id] = nil
        requests.remove(id)
        if requests.isEmpty {
            locationManager.stopUpdatingLocation()
        }
    }

    // MARK: - Permission Request Helper

    /// Requests location permission from the user.
    /// - Parameter authorizationContinuation: A continuation that will be resumed once the user responds to the permission request.
    func askForPermission(authorizationContinuation: CheckedContinuation<Void, Error>) {
        self.authorizationContinuation = authorizationContinuation
        Task { @MainActor in
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Location Handling

    /// Sends the most recent location update to the continuation.
    /// - Parameter location: The new location to send.
    func send(location: CLLocation) {
        print("Location did update", location)
        continuations.forEach { $0.value?.yield(location) }
    }

    /// Handles the result of a location permission request.
    /// - Parameter status: The authorization status returned by the system.
    func proceed(withAuthorization status: CLAuthorizationStatus) {
        defer { authorizationContinuation = nil }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // If permission is granted, resume the continuation without error.
            authorizationContinuation?.resume()
            return

        case .notDetermined, .denied, .restricted:
            // If permission is denied or restricted, throw an error.
            authorizationContinuation?.resume(throwing: LocationServicesError.denied)
            return

        @unknown default:
            // Handle any future cases that might be added to the authorization status enum.
            return
        }
    }

    // MARK: - CLLocationManagerDelegate Conformance

    /// Delegate method that is called when the location manager receives new location data.
    /// - Parameter manager: The CLLocationManager object that generated the event.
    /// - Parameter locations: An array of CLLocation objects containing the location data.
    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { await send(location: location) }
    }

    /// Delegate method that is called when the authorization status for the app changes.
    /// - Parameter manager: The CLLocationManager object that generated the event.
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }
        Task { await proceed(withAuthorization: status) }
    }
}
