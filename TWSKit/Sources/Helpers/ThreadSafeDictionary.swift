//
//  ThreadSafeDictionary.swift
//  TWSKit
//
//  Created by Miha Hozjan on 25. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public class ThreadSafeDictionary<U: Hashable, V> {
    private let queue = DispatchQueue(label: "ThreadSafeDictionaryQueue", attributes: .concurrent)
    private var _value = [U: V]()

    public init() { }

    public subscript(index: U) -> V? {
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

    public var value: [U: V] {
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

    public var count: Int {
        var result = 0
        queue.sync { result = self._value.count }
        return result
    }

    public func removeValue(forKey key: U, completion: ((V?) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let result = self._value.removeValue(forKey: key)

            DispatchQueue.global().async {
                completion?(result)
            }
        }
    }
}
