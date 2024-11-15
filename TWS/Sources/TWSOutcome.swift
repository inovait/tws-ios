//
//  TWSOutcome.swift
//  TWS
//
//  Created by Miha Hozjan on 15. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels

@MainActor
@Observable
public class TWSOutcome<T>: @preconcurrency CustomDebugStringConvertible {

    public internal(set) var items: T
    public internal(set) var state: TWSLoadingState

    public init(items: T, state: TWSLoadingState) {
        self.items = items
        self.state = state
    }

    public func callAsFunction() -> T {
        items
    }

    public var debugDescription: String {
        switch state {
        case .idle:
            return "Idle"

        case .loading:
            return "Loading..."

        case .loaded:
            if let items = items as? [TWSSnippet] {
                return "Loaded (\(items.count))"
            } else {
                return "Loaded"
            }

        case let .failed(error):
            return "Failed: \(error.localizedDescription)"
        }
    }
}
