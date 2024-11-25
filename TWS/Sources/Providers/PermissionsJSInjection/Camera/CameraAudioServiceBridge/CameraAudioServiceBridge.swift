//
//  CameraAudioServiceBridge.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 28. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
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
