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

    private static var _instances = ThreadSafeDictionary<TWSConfiguration, WeakBox<TWSManager>>()

    /// Creates and returns a new instance of ``TWSManager``
    /// - Parameter configuration: Configuration of a project you would like to show
    /// - Returns: An instance of ``TWSManager
    public class func new(
        with configuration: TWSConfiguration
    ) -> TWSManager {
        _new(
            configuration: configuration,
            snippets: nil,
            socketURL: nil
        )
    }

    /// Sets up the TWS manager
    /// - Parameter shared: Information about the TWSSnippet opened via universal link
    /// - Returns: An instance of ``TWSManager``
    public class func new(
        with shared: TWSSharedSnippet
    ) -> TWSManager {
        return _new(
            configuration: shared.configuration,
            snippets: [shared.snippet],
            socketURL: nil
        )
    }

    // MARK: - Internal

    class func destroy(
        configuration: TWSConfiguration
    ) {
        _instances.removeValue(forKey: configuration)
    }

    // MARK: - Helpers

    private class func _new(
        configuration: TWSConfiguration,
        snippets: [TWSSnippet]?,
        socketURL: URL?
    ) -> TWSManager {
        if let manager = _instances[configuration]?.box {
            logger.info("Reusing TWSManager for configuration: \(configuration)")
            return manager
        }

        let events = AsyncStream<TWSStreamEvent>.makeStream()
        let state = TWSCoreFeature.State(
            settings: .init(),
            snippets: .init(configuration: configuration, snippets: snippets, socketURL: socketURL),
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

        let manager = TWSManager(store: store, events: events.stream, configuration: configuration)
        logger.info("Created a new TWSManager for configuration: \(configuration)")
        _instances[configuration] = WeakBox(manager)
        return manager
    }
}
