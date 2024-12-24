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
