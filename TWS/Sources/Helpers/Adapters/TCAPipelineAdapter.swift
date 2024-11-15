//
//  TCAPipelineAdapter.swift
//  TWS
//
//  Created by Miha Hozjan on 6. 08. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
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
                case let .universalLinks(.delegate(.snippetLoaded(snippet))):
                    return .universalLinkSnippetLoaded(snippet)

                case .snippetsDidChange:
                    return .snippetsUpdated

                case .stateChanged:
                    return .stateChanged

                default:
                    return nil
                }
            }
        )
    }
}
