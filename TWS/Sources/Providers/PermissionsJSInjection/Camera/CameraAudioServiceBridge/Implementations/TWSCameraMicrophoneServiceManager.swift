//
//  CameraMicrophoneServiceManager.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 28. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import AVFoundation

final actor TWSCameraMicrophoneServiceManager: Observable, CameraMicrophoneServicesBridge {

    init() { }

    // MARK: - Confirming to `CameraMicrophoneServicesBridge`

    func checkCameraPermission() async throws(CameraMicrophoneServicesError) {
        // Check the current authorization status
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            // Permission already granted
            return
        case .notDetermined:
            // Request permission asynchronously
            let granted = await requestCameraPermission()
            if !granted {
                throw CameraMicrophoneServicesError.cameraNotGranted
            }
        default:
            // Permission denied or restricted
            throw CameraMicrophoneServicesError.cameraNotGranted
        }
    }

    func checkMicrophonePermission() async throws(CameraMicrophoneServicesError) {
        // Check the current authorization status
        let status = AVAudioApplication.shared.recordPermission

        switch status {
        case .granted:
            // Permission already granted
            return
        case .undetermined:
            // Request permission asynchronously
            let granted = await requestMicrophonePermission()
            if !granted {
                throw CameraMicrophoneServicesError.microphoneNotGranted
            }
        default:
            // Permission denied or restricted
            throw CameraMicrophoneServicesError.microphoneNotGranted
        }
    }

    // MARK: - Private Helper Methods

    private func requestCameraPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
