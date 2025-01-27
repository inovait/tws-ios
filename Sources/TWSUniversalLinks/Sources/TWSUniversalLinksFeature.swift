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
import ComposableArchitecture
import TWSCommon
@_spi(Internals) import TWSModels

@Reducer
public struct TWSUniversalLinksFeature: Sendable {

    @ObservableState
    public struct State: Equatable {
        public init() { }
    }

    @CasePathable
    public enum Action {

        @CasePathable
        public enum BusinessAction {
            case onUniversalLink(URL)
            case configurationLoaded(Result<TWSSharedConfiguration, Error>)
        }

        @CasePathable
        public enum DelegateAction {
            case configurationLoaded(TWSSharedConfiguration)
        }

        case business(BusinessAction)
        case delegate(DelegateAction)
    }

    public init() { }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .business(.onUniversalLink(url)):
            guard !url.isTWSAuthenticationRequest()
            else { return .none }
            logger.info("Received a universal link: \(url)")

            do {
                switch try TWSUniversalLinkRouter.route(for: url) {
                case let .snippet(id):
                    return .run { send in
                        await send(.business(.configurationLoaded(.success(TWSSharedConfiguration(id: id)))))
                    }
                }
            } catch {
                dump(error)
                logger.err("Failed to process an universal link: \(url), error: \(error.localizedDescription)")
                return .none
            }

        case let .business(.configurationLoaded(.success(config))):
            logger.info("Universal link: snippet loaded successfully")

            return .send(.delegate(.configurationLoaded(config)))

        case let .business(.configurationLoaded(.failure(error))):
            logger.err("Universal link: load failed: \(error.localizedDescription)")
            return .none

        case .delegate:
            return .none
        }
    }
}
