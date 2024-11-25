//
//  TWSRawCSS.swift
//  TWSModels
//
//  Created by Miha Hozjan on 20. 08. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// A structure representing raw CSS styles.
///
/// This struct provides a type-safe way to handle raw CSS strings, ensuring they can be used consistently throughout the application. It conforms to `ExpressibleByStringLiteral` for convenient initialization and can be encoded/decoded for persistence or transmission.
public struct TWSRawCSS: ExpressibleByStringLiteral, Codable, Equatable, Sendable {

    /// The raw CSS code as a string.
    public let value: String

    /// Initializes a new instance of `TWSRawCSS` with the provided CSS code.
    ///
    /// - Parameter value: The raw CSS string.
    public init(_ value: String) {
        self.init(stringLiteral: value)
    }

    /// Initializes a new instance of `TWSRawCSS` from a string literal.
    ///
    /// - Parameter stringLiteral: The raw CSS string.
    public init(stringLiteral: String) {
        self.value = stringLiteral
    }
}
