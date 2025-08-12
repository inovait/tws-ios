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
    case loading(progress: Double)
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
