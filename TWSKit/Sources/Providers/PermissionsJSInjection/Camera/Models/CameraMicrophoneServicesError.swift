//
//  CameraMicrophoneServicesError.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 28. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public enum CameraMicrophoneServicesError: Int, Error { case cameraNotGranted, microphoneNotGranted }
