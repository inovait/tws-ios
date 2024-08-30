//
//  JavaScriptLocationAdapter.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 28. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import CoreLocation
import WebKit

actor JavaScriptLocationAdapter: NSObject, WKScriptMessageHandler {

    private weak var webView: WKWebView?
    private weak var bridge: LocationServicesBridge?

    func bind(webView: WKWebView, to bridge: LocationServicesBridge?) {
        self.webView = webView
        self.bridge = bridge
    }

    // MARK: - Confirming to `WKScriptMessageHandler`

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard
            let payload = message.body as? String,
            let data = payload.data(using: .utf8),
            let message = try? JSONDecoder().decode(JSLocationMessage.self, from: data)
        else {
            assertionFailure("Failed to decode a message")
            return
        }

        Task { await _handle(message: message) }
    }

    // MARK: - Helpers

    private func _handle(message: JSLocationMessage) async {
        switch message.command {
        case .getCurrentPosition:
            do {
                try await bridge?.checkPermission()
            } catch let error as LocationServicesError {
                await _sendFailed(id: message.id, error: error)
                return
            } catch {
                await _sendFailed(id: message.id, error: .denied)
                return
            }

            guard let location = await bridge?.location(
                id: message.id,
                options: message.options
            ) else {
                await _sendFailed(id: message.id, error: .unavailable)
                return
            }

            await _send(id: message.id, location: location)

        case .watchPosition:
            do {
                try await bridge?.checkPermission()
            } catch let error as LocationServicesError {
                await _updateFailed(id: message.id, error: error)
                return
            } catch {
                await _updateFailed(id: message.id, error: .denied)
                return
            }

            guard let stream = await bridge?.startUpdatingLocation(
                id: message.id,
                options: message.options
            ) else {
                return
            }

            Task {
                for await location in stream {
                    await _update(location: location, forId: message.id)
                }
            }

        case .clearWatch:
            await bridge?.stopUpdatingLocation(id: message.id)
        }
    }

    // MARK: - Making calls back to JS

    @MainActor
    private func _update(location: CLLocation, forId id: Double) async {
        let coordinate = location.coordinate
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let alt = location.altitude
        let hoa = location.horizontalAccuracy
        let vea = location.verticalAccuracy
        let hed = location.course
        let spd = location.speed

        _ = try? await webView?.evaluateJavaScript(
            "navigator.geolocation.iosWatchLocationDidUpdate(\(id),\(lat),\(lon),\(alt),\(hoa),\(vea),\(hed),\(spd))"
        )
    }

    @MainActor
    private func _updateFailed(id: Double, error: LocationServicesError) async {
        _ = try? await webView?.evaluateJavaScript(
            "navigator.geolocation.iosWatchLocationDidFailed(\(id),\(error.rawValue))"
        )
    }

    @MainActor
    private func _send(id: Double, location: CLLocation) async {
        let coordinate = location.coordinate
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let alt = location.altitude
        let hoa = location.horizontalAccuracy
        let vea = location.verticalAccuracy
        let hed = location.course
        let spd = location.speed

        _ = try? await webView?.evaluateJavaScript(
            "navigator.geolocation.iosLastLocation(\(id),\(lat),\(lon),\(alt),\(hoa),\(vea),\(hed),\(spd))"
        )
    }

    @MainActor
    private func _sendFailed(id: Double, error: LocationServicesError) async {
        _ = try? await webView?.evaluateJavaScript(
            "navigator.geolocation.iosLastLocationFailed(\(id),\(error.rawValue))"
        )
    }
}
