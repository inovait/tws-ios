//
//  CameraAudioServiceBridge.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 28. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// An camera-microphone service interface used to communicate between the JavaScript world and the iOS world
public protocol CameraMicrophoneServicesBridge: Actor {

    func checkCameraPermission() async throws
    func checkMicrophonePermission() async throws
}
