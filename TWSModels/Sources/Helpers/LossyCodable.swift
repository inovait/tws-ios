//
//  LossyCodable.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 22. 08. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

@propertyWrapper
public struct LossyCodableList<Element> {

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

extension LossyCodableList: Decodable where Element: Decodable {

    private struct ElementWrapper: Decodable {

        var element: Element?

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            element = try? container.decode(Element.self)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let wrappers = try? container.decode([ElementWrapper].self) {
            elements = wrappers.compactMap(\.element)
        } else {
            elements = nil
        }
    }
}

extension LossyCodableList: Encodable where Element: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        if let elements {
            for element in elements {
                try? container.encode(element)
            }
        }
    }
}
