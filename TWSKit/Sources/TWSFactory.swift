//
//  TWSFactory.swift
//  TWSKit
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels
@_implementationOnly import TWSCore
@_implementationOnly import TWSSettings
@_implementationOnly import TWSSnippets
@_implementationOnly import TWSSnippet
@_implementationOnly import ComposableArchitecture

public class TWSFactory {

    public class func new() -> TWSManager {
        let snippetsStream = AsyncStream<TWSStreamEvent>.makeStream()
        let state = TWSCoreFeature.State(
            settings: .init(),
            snippets: .init(),
            universalLinks: .init()
        )

        let storage = state.snippets.snippets.map(\.snippet)
        logger.info(
            "\(storage.count) \(storage.count == 1 ? "snippet" : "snippets") loaded from disk"
        )

        let combinedReducers = CombineReducers {
            Reduce<TWSCoreFeature.State, TWSCoreFeature.Action> { _, action in
                switch action {
                case let .universalLinks(.delegate(.snippetLoaded(snippet))):
                    snippetsStream.continuation.yield(.snippetLoaded(snippet))
                    return .none
                default:
                    return .none
                }
            }
            TWSCoreFeature()
                .onChange(of: \.snippets.snippets) { _, newValue in
                    Reduce { _, _ in
                        let newSnippets = newValue.filter({ snippetState in
                            !snippetState.isPrivate
                        }).map(\.snippet)
                        snippetsStream.continuation.yield(.snippetsLoaded(newSnippets))
                        return .none
                    }
                }
        }

        let store = Store(
            initialState: state,
            reducer: { combinedReducers }
        )

        snippetsStream.continuation.yield(.snippetsLoaded(storage))

        return TWSManager(store: store, snippetsStream: snippetsStream.stream)
    }
}
