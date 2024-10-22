//
//  TWSSnippets+Props.swift
//  TWSModels
//
//  Created by Miha Hozjan on 21. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public extension TWSSnippet {

    enum Props: Codable, Hashable, Sendable {

        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        case dictionary([String: Props])
        case array([Props])

        // MARK: - Custom decoding

        public init(from decoder: Decoder) throws {

            if let keyedContainer = try? decoder.container(keyedBy: GenericCodingKeys.self) {
                self = Self(from: keyedContainer)
            } else if let unkeyedContainer = try? decoder.unkeyedContainer() {
                self = Self(from: unkeyedContainer)
            } else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unable to decode as either a keyed container or unkeyed container."
                ))
            }
        }

        private init(from decoder: KeyedDecodingContainer<GenericCodingKeys>) {
            var dictionary: [String: Props] = [:]

            for key in decoder.allKeys {
                if let string = try? decoder.decode(String.self, forKey: key) {
                    dictionary[key.stringValue] = .string(string)
                } else if let string = try? decoder.superDecoder().singleValueContainer().decode(String.self) {
                    dictionary[key.stringValue] = .string(string)
                } else if let int = try? decoder.decode(Int.self, forKey: key) {
                    dictionary[key.stringValue] = .int(int)
                } else if let int = try? decoder.superDecoder().singleValueContainer().decode(Int.self) {
                    dictionary[key.stringValue] = .int(int)
                } else if let double = try? decoder.decode(Double.self, forKey: key) {
                    dictionary[key.stringValue] = .double(double)
                } else if let bool = try? decoder.decode(Bool.self, forKey: key) {
                    dictionary[key.stringValue] = .bool(bool)
                } else if let nestedContainer = try? decoder.nestedContainer(
                    keyedBy: GenericCodingKeys.self,
                    forKey: key
                ) {
                    dictionary[key.stringValue] = Self(from: nestedContainer)
                } else if let nestedContainer = try? decoder.nestedUnkeyedContainer(forKey: key) {
                    dictionary[key.stringValue] = Self(from: nestedContainer)
                }
            }

            self = .dictionary(dictionary)
        }

        private init(from decoder: any UnkeyedDecodingContainer) {
            var decoder = decoder
            var arr: [Props] = []
            while !decoder.isAtEnd {
                if let string = try? decoder.decode(String.self) {
                    arr.append(.string(string))
                } else if let int = try? decoder.decode(Int.self) {
                    arr.append(.int(int))
                } else if let double = try? decoder.decode(Double.self) {
                    arr.append(.double(double))
                } else if let bool = try? decoder.decode(Bool.self) {
                    arr.append(.bool(bool))
                } else if let nestedContainer = try? decoder.nestedContainer(keyedBy: GenericCodingKeys.self) {
                    arr.append(Self(from: nestedContainer))
                } else if let nestedContainer = try? decoder.nestedUnkeyedContainer() {
                    arr.append(Self(from: nestedContainer))
                }
            }

            self = .array(arr)
        }

        // MARK: - Encoding

        public func encode(to encoder: any Encoder) throws {
            switch self {
            case let .string(value):
                var container = encoder.singleValueContainer()
                try container.encode(value)

            case let .int(value):
                var container = encoder.singleValueContainer()
                try container.encode(value)

            case let .double(value):
                var container = encoder.singleValueContainer()
                try container.encode(value)

            case let .bool(value):
                var container = encoder.singleValueContainer()
                try container.encode(value)

            case let .dictionary(dict):
                var container = encoder.container(keyedBy: GenericCodingKeys.self)
                for (key, value) in dict {
                    let key = GenericCodingKeys(stringValue: key)!
                    try container.encode(value, forKey: key)
                }

            case let .array(array):
                var container = encoder.unkeyedContainer()
                for item in array {
                    try container.encode(item)
                }
            }
        }

        // MARK: - Dynamic keys

        public final class GenericCodingKeys: CodingKey {

            public let stringValue: String
            public let intValue: Int?

            required public init?(stringValue: String) {
                self.stringValue = stringValue
                self.intValue = nil
            }

            required public init?(intValue: Int) {
                self.stringValue = "\(intValue)"
                self.intValue = intValue
            }
        }

        // MARK: - Helpers

        public var string: String? {
            switch self {
            case let .string(value): return value
            case .int, .bool, .double, .dictionary, .array: return nil
            }
        }

        public var int: Int? {
            switch self {
            case let .int(value): return value
            case .string, .bool, .double, .dictionary, .array: return nil
            }
        }

        public var double: Double? {
            switch self {
            case let .double(value): return value
            case .int, .bool, .string, .dictionary, .array: return nil
            }
        }

        public var bool: Bool? {
            switch self {
            case let .bool(value): return value
            case .int, .string, .double, .dictionary, .array: return nil
            }
        }

        public var dictionary: [String: Props]? {
            switch self {
            case let .dictionary(value): return value
            case .int, .bool, .double, .string, .array: return nil
            }
        }

        public var array: [Props]? {
            switch self {
            case let .array(value): return value
            case .int, .bool, .double, .string, .dictionary: return nil
            }
        }

        // MARK: - Subscript helper

        public subscript(_ key: String) -> Props? {
            guard case let .dictionary(dict) = self
            else { assertionFailure(); return nil }
            return dict[key]
        }

        public subscript<T>(_ key: String, as keyPath: KeyPath<Self, T?>) -> T? {
            guard let value = self[key]
            else { return nil }
            return value[keyPath: keyPath]
        }
    }
}
