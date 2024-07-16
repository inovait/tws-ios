//
//  TWSSource.swift
//  TWSKit
//
//  Created by Miha Hozjan on 6. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public enum TWSSource: Codable, Equatable {

    case api
    case customURLs([URL])
}
