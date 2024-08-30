//
//  DefaultLocationServiceModifier.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 30. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

private struct DefaultLocationServiceModifier: ViewModifier {

    let locationServicesBridge: LocationServicesBridge
    let snippet: TWSSnippet
    let displayID: String

    func body(content: Content) -> some View {
        content
            // Default Location Services implementation - start on appear
            .onAppear {
                guard let bridge = _unbox() else { return }
                bridge.didAppear(snippet: snippet, displayID: displayID)
            }
            // Default Location Services implementation - stop on dissappear
            .onDisappear {
                guard let bridge = _unbox() else { return }
                bridge.didDisappear(snippet: snippet, displayID: displayID)
            }
            // Stop on background transition
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.didEnterBackgroundNotification
                ),
                perform: { _ in
                    guard let bridge = _unbox() else { return }
                    bridge.onBackgroundTransition()
                }
            )
            // Resume on foreground transition
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification
                ),
                perform: { _ in
                    guard let bridge = _unbox() else { return }
                    bridge.onForegroundTransition()
                }
            )

    }

    private func _unbox() -> TWSDefaultLocationServicesManager? {
        guard
            let locationServicesBridge = locationServicesBridge as? TWSDefaultLocationServicesManager
        else {
            return nil
        }

        return locationServicesBridge
    }
}

extension View {

    func conditionallyActivateDefaultLocationBehavior(
        locationServicesBridge: LocationServicesBridge,
        snippet: TWSSnippet,
        displayID: String
    ) -> some View {
        self.modifier(DefaultLocationServiceModifier(
            locationServicesBridge: locationServicesBridge,
            snippet: snippet,
            displayID: displayID
        ))
    }
}
