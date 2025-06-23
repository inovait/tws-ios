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
import Combine
internal import TWSCore
internal import ComposableArchitecture

protocol MVVMAdapter: Reducer {

    associatedtype ChildReducerState
    associatedtype ChildReducerAction
    associatedtype Notification

    var publisher: PassthroughSubject<Notification, Never> { get }
    var childReducer: any Reducer<ChildReducerState, ChildReducerAction> { get }
    var casePath: AnyCasePath<ChildReducerAction, Notification> { get }
}

extension MVVMAdapter where State == ChildReducerState, Action == ChildReducerAction {

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        let effects = childReducer.reduce(into: &state, action: action)
        if let notification = casePath.extract(from: action) { publisher.send(notification) }
        return effects
    }
}

extension AnyCasePath {

    static var tws: AnyCasePath<TWSCoreFeature.Action, TWSStreamEvent> {
        .init(
            embed: { _ in fatalError("Embedding is no valid") },
            extract: { action in
                switch action {
                case let .universalLinks(.delegate(.configurationLoaded(config))):
                    return .universalLinkConfigurationLoaded(config)

                case .snippetsDidChange:
                    return .snippetsUpdated

                case .stateChanged:
                    return .stateChanged
            
                case .openOverlay(let snippet):
                    Task { @MainActor in
                        @Dependency(\.configuration) var config
                        guard let manager = TWSFactory.get(with: config.configuration()) else {
                            logger.warn("Can not open overlay for snippet \(snippet), because TWSManager does not exist for the configuration")
                            return
                        }
                        
                        TWSOverlayProvider.shared.showOverlay(snippet: snippet, manager: manager, type: .campaign)
                    }
                    return .shouldOpenCampaign
                default:
                    return nil
                }
            }
        )
    }
}
