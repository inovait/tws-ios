//
//  TWSLoadingState.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 26. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// An enum to define the loading status of the snippet
@frozen
public enum TWSLoadingState: Equatable, Sendable {

    public static func == (lhs: TWSLoadingState, rhs: TWSLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): true
        case (.loading, .loading): true
        case (.loaded, .loaded): true
        case let (.failed(err1), .failed(err2)): err1.same(as: err2)
        default: false
        }
    }

    case idle
    case loading
    case loaded
    case failed(Error)
}

private extension Error {

    func same<T: Error>(as error: T) -> Bool {
        if let error = self as? T {
            return "\(self)" == "\(error)"
        }

        return false
    }
}

extension TWSLoadingState {

    /// A flag that defines if the view can be shown, depending on it's loading state
    @_spi(Internals) public var showView: Bool {
        switch self {
        case .idle, .loading, .failed: false
        case .loaded: true
        }
    }

    @_spi(Internals) public var canLoad: Bool {
        switch self {
        case .idle, .loaded, .failed: true
        case .loading: false
        }
    }
}
