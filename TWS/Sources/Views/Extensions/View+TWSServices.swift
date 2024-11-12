//
//  View+TWSLocationServices.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 22. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

final private class DefaultImplementations: Sendable {

    let locationServicesBridge = DefaultLocationServicesManager()
    let cameraMicrophoneServiceBridge = TWSCameraMicrophoneServiceManager()

    static let shared = DefaultImplementations()
}

extension View {

    public func bind(
        locationServiceBridge: some LocationServicesBridge
    ) -> some View {
        self
            .environment(\.locationServiceBridge, locationServiceBridge)
    }

    public func bind(
        cameraMicrophoneServiceBridge: some CameraMicrophoneServicesBridge
    ) -> some View {
        self
            .environment(\.cameraMicrophoneServiceBridge, cameraMicrophoneServiceBridge)
    }
}

extension EnvironmentValues {

    @Entry var locationServiceBridge: LocationServicesBridge = DefaultImplementations
        .shared
        .locationServicesBridge

    @Entry var cameraMicrophoneServiceBridge: CameraMicrophoneServicesBridge = DefaultImplementations
        .shared
        .cameraMicrophoneServiceBridge
}
