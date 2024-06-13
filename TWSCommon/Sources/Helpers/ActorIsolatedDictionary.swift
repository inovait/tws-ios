//
//  ActorIsolatedDictionary.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 13. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public final actor ActorIsolatedDictionary<Key: Hashable, Value> {

    private var dictionary: [Key: Value]

    public init(_ dictionary: @autoclosure @Sendable () throws -> [Key: Value]) rethrows {
        self.dictionary = try dictionary()
    }

    public func withDictionary<T>(
        _ operation: @Sendable (inout [Key: Value]) throws -> T
    ) rethrows -> T {
        var dictionary = self.dictionary
        defer { self.dictionary = dictionary }
        return try operation(&dictionary)
    }

    public func setDictionary(_ newDictionary: @autoclosure @Sendable () throws -> [Key: Value]) rethrows {
        self.dictionary = try newDictionary()
    }

    public func getValue(forKey key: Key) async -> Value? {
        return dictionary[key]
    }

    public func setValue(_ value: @autoclosure @Sendable () throws -> Value, forKey key: Key) rethrows {
        dictionary[key] = try value()
    }

    public func removeValue(forKey key: Key) async {
        dictionary.removeValue(forKey: key)
    }
}
