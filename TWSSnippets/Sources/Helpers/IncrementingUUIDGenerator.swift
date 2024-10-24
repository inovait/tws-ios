//
//  TWSSnippetsFeature+IncrementingUUIDGenerator.swift
//  TWSSnippets
//
//  Created by Miha Hozjan on 6. 08. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

class IncrementingUUIDGenerator: @unchecked Sendable {

    private var sequence = 0

    func callAsFunction() -> String {
        defer {
            self.sequence += 1
        }

        return String(self.sequence)
    }
}
