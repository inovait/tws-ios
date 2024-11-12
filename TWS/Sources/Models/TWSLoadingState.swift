//
//  TWSLoadingState.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 26. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// An enum to define the loading status of the snippet
public enum TWSLoadingState: Equatable {

    public static func == (lhs: TWSLoadingState, rhs: TWSLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): true
        case (.loading, .loading): true
        case (.loaded, .loaded): true
        case (.failed, .failed): true
        default: false
        }
    }

    case idle
    case loading
    case loaded
    case failed(Error)
}

extension TWSLoadingState {

    /// A flag that defines if the view can be shown, depending on it's loading state
    var showView: Bool {
        switch self {
        case .idle, .loading, .failed: false
        case .loaded: true
        }
    }
}
