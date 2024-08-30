//
//  LocationServicesError.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 28. 8. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

enum LocationServicesError: Int, Error { case denied = 1, unavailable, timeout }
