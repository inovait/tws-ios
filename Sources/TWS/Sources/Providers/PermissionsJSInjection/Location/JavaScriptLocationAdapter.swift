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
import CoreLocation
import WebKit

class JavaScriptLocationMessageHandler: NSObject, WKScriptMessageHandler {

    private let adapter: JavaScriptLocationAdapter

    init(adapter: JavaScriptLocationAdapter) {
        self.adapter = adapter
    }

    // MARK: - Confirming to `WKScriptMessageHandler`

    @MainActor
    func userContentController(
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

        Task { [weak self] in
            guard let self else { return }
            await self.adapter._handle(message: message)
        }
    }
}

actor JavaScriptLocationAdapter {

    private weak var webView: WKWebView?
    private weak var bridge: LocationServicesBridge?

    func bind(webView: WKWebView, to bridge: LocationServicesBridge?) {
        self.webView = webView
        self.bridge = bridge
    }

    // MARK: - Helpers

    fileprivate func _handle(message: JSLocationMessage) async {
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
