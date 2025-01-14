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

class ThreadSafeDictionary<U: Hashable & Sendable, V: Sendable>: @unchecked Sendable {
    private let queue = DispatchQueue(label: "ThreadSafeDictionaryQueue", attributes: .concurrent)
    private var _value = [U: V]()

    init() { }

    subscript(index: U) -> V? {
        get {
            var result: V?
            queue.sync {
                result = _value[index]
            }
            return result

        } set {
            queue.async(flags: .barrier) {
                self._value[index] = newValue
            }
        }
    }

    // periphery:ignore
    var value: [U: V] {
        get {
            var value: [U: V]!
            queue.sync { value = self._value }
            return value
        } set {
            queue.async(flags: .barrier) {
                self._value = newValue
            }
        }
    }

    // periphery:ignore
    var count: Int {
        var result = 0
        queue.sync { result = self._value.count }
        return result
    }

    func removeValue(forKey key: U, completion: (@Sendable (V?) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let result = self._value.removeValue(forKey: key)

            DispatchQueue.global().async {
                completion?(result)
            }
        }
    }
}
