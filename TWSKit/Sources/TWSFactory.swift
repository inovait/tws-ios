//
//  TWSFactory.swift
//  TWSKit
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
@_implementationOnly import TWSCore
@_implementationOnly import TWSSettings
@_implementationOnly import TWSSnippets
@_implementationOnly import TWSSnippet
@_implementationOnly import ComposableArchitecture

/// A class designed to initialize a new ``TWSManager``
public class TWSFactory {

    private static var _instances = ThreadSafeSet<TWSConfiguration>()

    /// Sets up the app's reducers and main store
    /// - Returns: An instance of ``TWSManager``
    public class func new(
        with configuration: TWSConfiguration
    ) -> TWSManager {
        defer { _instances.insert(configuration) }
        guard !_instances.contains(configuration)
        else { preconditionFailure(
            """
            Only one instance per configuration is allowed.
            Due to an unknown limitation, if two connections are established simultaneously,
            one will drop the other.
            """
        )}

        let events = AsyncStream<TWSStreamEvent>.makeStream()
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
                    // Hop the thread
                    DispatchQueue.main.async {
                        events.continuation.yield(.universalLinkSnippetLoaded(snippet))
                    }

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
                        // Hop the thread
                        DispatchQueue.main.async {
                            events.continuation.yield(.snippetsUpdated(newSnippets))
                        }

                        return .none
                    }
                }
        }
        // Set the environment
        .dependency(\.configuration.configuration, { configuration })

        let store = Store(
            initialState: state,
            reducer: { combinedReducers }
        )

        events.continuation.yield(.snippetsUpdated(storage))

        return TWSManager(store: store, events: events.stream)
    }
}
