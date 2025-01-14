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

import SwiftUI

final private class DefaultImplementations: Sendable {

    let locationServicesBridge = DefaultLocationServicesManager()
    let cameraMicrophoneServiceBridge = TWSCameraMicrophoneServiceManager()

    static let shared = DefaultImplementations()
}

extension View {

    public func twsBind(
        locationServiceBridge: some LocationServicesBridge
    ) -> some View {
        self
            .environment(\.locationServiceBridge, locationServiceBridge)
    }

    public func twsBind(
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
