//
//  TWSRawCSS.swift
//  TWSModels
//
//  Created by Miha Hozjan on 20. 08. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public struct TWSRawCSS: ExpressibleByStringLiteral, Codable, Equatable, Sendable {

    public let value: String

    public init(_ value: String) {
        self.init(stringLiteral: value)
    }

    public init(stringLiteral: String) {
        self.value = stringLiteral
    }
}
