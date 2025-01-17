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
