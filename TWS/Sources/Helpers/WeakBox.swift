//
//  WeakBox.swift
//  TWS
//
//  Created by Miha Hozjan on 25. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

@MainActor
final class WeakBox<T: AnyObject> {
    weak private(set) var box: T?

    init(_ box: T) {
        self.box = box
    }
}

extension WeakBox: @unchecked Sendable where T: Sendable { }
