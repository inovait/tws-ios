//
//  ThreadSafeDictionary.swift
//  TWSKit
//
//  Created by Miha Hozjan on 17. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

class ThreadSafeSet<T: Hashable> {

    private let queue = DispatchQueue(label: "ThreadSafeDictionaryQueue")
    private var _value = Set<T>()

    func contains(_ item: T) -> Bool {
        var result = false
        queue.sync { result = self._value.contains(item) }
        return result
    }

    func insert(_ item: T) {
        queue.async { self._value.insert(item) }
    }
}
