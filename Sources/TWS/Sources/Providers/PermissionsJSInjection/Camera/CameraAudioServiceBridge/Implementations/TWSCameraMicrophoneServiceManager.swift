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
