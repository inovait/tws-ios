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

@preconcurrency import CoreLocation
import SwiftUI
import TWSModels

// Define an actor class that handles location services and acts as a bridge to your application's logic.
final actor DefaultLocationServicesManager: NSObject,
        LocationServicesBridge,
        Observable,
        CLLocationManagerDelegate {

    // MARK: - Properties

    // The CLLocationManager instance responsible for managing location services.
    private let locationManager: CLLocationManager

    // Continuation for asynchronously streaming location updates.
    private var continuations: [Double: AsyncStream<CLLocation>.Continuation] = [:]

    // Continuation for asynchronously streaming location updates.
    private var singleContinuations: [Double: CheckedContinuation<CLLocation?, Never>] = [:]

    // Continuation for handling permission requests asynchronously.
    private var authorizationContinuation: CheckedContinuation<Void, Error>?

    // Keep track of requests
    private var requests = Set<Double>()

    // Identifiers of views who are visible
    private var visibleViews = Set<String>()

    // MARK: - Initializer

    /// Initializes a new instance of DefaultLocationServicesBridge.
    /// - Parameter locationManager: A custom CLLocationManager instance, defaulting to a new instance if not provided.
    init(
        locationManager: CLLocationManager = .init()
    ) {
        logger.debug("INIT LocationManager @ \(Date())")
        self.locationManager = locationManager
        super.init()

        // Set the location manager's delegate to self.
        self.locationManager.delegate = self
    }

    // MARK: - LocationServicesBridge Protocol Conformance

    /// Checks and requests location permissions as needed.
    /// Throws an error if the user denies or restricts access to location services.
    func checkPermission() async throws {
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
    /// - id: A unique identifier for the location update session
    ///   - options: An instance of `JSLocationMessageOptions` that specifies options such as maximum age, timeout, and accuracy for the location updates.
    /// - Returns: The last known location, or `nil` if no location is available.
    func location(id: Double, options _: JSLocationMessageOptions?) async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            Task { _set(id: id, locationContinuation: continuation)}
        }
    }

    /// Begins streaming continuous location updates.
    /// - Parameters:
    ///   - id: A unique identifier for the location update session
    ///   - options: An instance of `JSLocationMessageOptions` that specifies options such as maximum age, timeout, and accuracy for the location updates.
    /// - Returns: An `AsyncStream` that yields `CLLocation` objects as the device's location updates.
    func startUpdatingLocation(id: Double, options _: JSLocationMessageOptions?) -> AsyncStream<CLLocation> {
        let stream = AsyncStream<CLLocation>.makeStream()
        continuations[id] = stream.continuation
        locationManager.startUpdatingLocation()
        requests.insert(id)
        return stream.stream
    }

    /// Stops the continuous location updates associated with the specified session ID.
    /// - Parameter id: The unique identifier for the location update session to stop.
    func stopUpdatingLocation(id: Double) {
        continuations[id]?.finish()
        continuations[id] = nil
        requests.remove(id)
        if requests.isEmpty {
            locationManager.stopUpdatingLocation()
        }
    }

    // MARK: - Helpers - start location services when views are presented, stop on dismiss

    nonisolated func didAppear(snippet: TWSSnippet, displayID: String) {
        Task { await _didAppear(snippet: snippet, displayID: displayID) }
    }

    private func _didAppear(snippet: TWSSnippet, displayID: String) {
        let id = _id(for: snippet, withDisplayID: displayID)
        visibleViews.insert(id)
        if !requests.isEmpty { locationManager.startUpdatingLocation() }
    }

    nonisolated func didDisappear(snippet: TWSSnippet, displayID: String) {
        Task { await _didDisappear(snippet: snippet, displayID: displayID) }
    }

    private func _didDisappear(snippet: TWSSnippet, displayID: String) {
        let id = _id(for: snippet, withDisplayID: displayID)
        visibleViews.remove(id)
        if visibleViews.isEmpty { locationManager.stopUpdatingLocation() }
    }

    nonisolated func onForegroundTransition() {
        Task { await _onForegroundTransition() }
    }

    private func _onForegroundTransition() {
        guard !requests.isEmpty && !visibleViews.isEmpty
        else { return }
        locationManager.startUpdatingLocation()
    }

    nonisolated func onBackgroundTransition() {
        Task { await _onBackgroundTransition() }
    }

    private func _onBackgroundTransition() {
        locationManager.stopUpdatingLocation()
    }

    private func _set(
        id: Double,
        locationContinuation: CheckedContinuation<CLLocation?, Never>
    ) {
        singleContinuations[id] = locationContinuation
        locationManager.startUpdatingLocation()
    }

    // MARK: - Permission Request Helper

    /// Requests location permission from the user.
    /// - Parameter authorizationContinuation: A continuation that will be resumed once the user responds to the permission request.
    func askForPermission(authorizationContinuation: CheckedContinuation<Void, Error>) {
        self.authorizationContinuation = authorizationContinuation
        Task { @MainActor [locationManager] in
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Location Handling

    /// Sends the most recent location update to the continuations.
    /// - Parameter location: The new location to send.
    func send(location: CLLocation) {
        continuations.forEach { $0.value.yield(location) }

        if !singleContinuations.isEmpty {
            for key in singleContinuations.keys {
                let continuation = singleContinuations.removeValue(forKey: key)
                continuation?.resume(returning: location)
            }

            if requests.isEmpty {
                locationManager.stopUpdatingLocation()
            }
        }
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
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { await send(location: location) }
    }

    /// Delegate method that is called when the authorization status for the app changes.
    /// - Parameter manager: The CLLocationManager object that generated the event.
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }
        Task { await proceed(withAuthorization: status) }
    }

    // MARK: - Helpers

    private func _id(for snippet: TWSSnippet, withDisplayID displayID: String) -> String {
        "\(snippet.id)-\(displayID)"
    }
}
