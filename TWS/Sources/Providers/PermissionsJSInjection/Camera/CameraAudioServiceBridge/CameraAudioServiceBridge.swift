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

/// A protocol defining a service interface for camera and microphone interactions.
///
/// This interface is designed to facilitate communication between the JavaScript environment and the iOS environment, handling permission checks for the camera and microphone.
///
/// > Note: By default, permissions are requested when a browser needs them. You can provide your own implementation.
///
/// To provide a custom implementation, use the ``SwiftUICore/View/twsBind(cameraMicrophoneServiceBridge:)`` helper function.
public protocol CameraMicrophoneServicesBridge: Actor {

    /// Checks the camera permission status.
    ///
    /// - Throws: A ``CameraMicrophoneServicesError`` if an error occurs while checking the permission.
    /// - Returns: Nothing. The result is inferred through success or failure.
    func checkCameraPermission() async throws(CameraMicrophoneServicesError)

    /// Checks the microphone permission status.
    ///
    /// - Throws: A ``CameraMicrophoneServicesError`` if an error occurs while checking the permission.
    /// - Returns: Nothing. The result is inferred through success or failure.
    func checkMicrophonePermission() async throws(CameraMicrophoneServicesError)
}
