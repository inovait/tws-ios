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

/// A structure representing raw JavaScript code.
///
/// This struct provides a type-safe way to handle raw JavaScript strings, ensuring they can be used consistently throughout the application. It conforms to `ExpressibleByStringLiteral` for convenient initialization and can be encoded/decoded for persistence or transmission.
public struct TWSRawJS: ExpressibleByStringLiteral, Codable, Equatable, Sendable {

    /// The raw JavaScript code as a string.
    public let value: String

    /// Initializes a new instance of `TWSRawJS` with the provided JavaScript code.
    ///
    /// - Parameter value: The raw JavaScript string.
    public init(_ value: String) {
        self.init(stringLiteral: value)
    }

    /// Initializes a new instance of `TWSRawJS` from a string literal.
    ///
    /// - Parameter stringLiteral: The raw JavaScript string.
    public init(stringLiteral: String) {
        self.value = stringLiteral
    }
}
