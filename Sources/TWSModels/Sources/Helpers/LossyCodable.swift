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

@propertyWrapper
@_spi(Internals) public struct LossyCodableList<Element: Sendable>: Sendable {

    private var elements: [Element]?

    public init(elements: [Element]?) {
        self.elements = elements
    }

    public var wrappedValue: [Element]? {
        get { elements }
        set { elements = newValue }
    }
}

// MARK: - Conditional conformances

extension LossyCodableList: Equatable where Element: Equatable { }

extension LossyCodableList: Hashable where Element: Hashable { }

extension LossyCodableList: Decodable where Element: Decodable {

    private struct ElementWrapper: Decodable {

        var element: Element?

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            element = try? container.decode(Element.self)
        }
    }

    @_spi(Internals) public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let wrappers = try? container.decode([ElementWrapper].self) {
            elements = wrappers.compactMap(\.element)
        } else {
            elements = nil
        }
    }
}

extension LossyCodableList: Encodable where Element: Encodable {

    @_spi(Internals) public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        if let elements {
            for element in elements {
                try? container.encode(element)
            }
        }
    }
}
