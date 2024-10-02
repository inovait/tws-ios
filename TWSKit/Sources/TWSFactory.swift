//
//  TWSFactory.swift
//  TWSKit
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import Combine
internal import TWSCore
internal import TWSSettings
internal import TWSSnippets
internal import TWSSnippet
internal import ComposableArchitecture

/// A class designed to initialize a new ``TWSManager``
@MainActor
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
            preloadedResources: [:],
            socketURL: nil
        )
    }

    /// Sets up the TWS manager
    /// - Parameter shared: Information about the TWSSnippet opened via universal link
    /// - Returns: An instance of ``TWSManager``
    public class func new(
        with shared: TWSSharedSnippetBundle
    ) -> TWSManager {
        return _new(
            configuration: shared.configuration,
            snippets: [shared.snippet],
            preloadedResources: ExtractResources.from(bundle: shared),
            socketURL: nil
        )
    }

    // MARK: - Internal

    class func destroy(
        configuration: TWSConfiguration
    ) {
        _instances.removeValue(forKey: configuration)

        Task { @MainActor in
            @Dependency(\.socket) var socket
            await socket.abort(configuration)
        }
    }

    // MARK: - Helpers

    private class func _new(
        configuration: TWSConfiguration,
        snippets: [TWSSnippet]?,
        preloadedResources: [TWSSnippet.Attachment: String],
        socketURL: URL?
    ) -> TWSManager {
        if let manager = _instances[configuration]?.box {
            logger.info("Reusing TWSManager for configuration: \(configuration)")
            return manager
        }

        let events = AsyncStream<TWSStreamEvent>.makeStream()
        let state = TWSCoreFeature.State(
            settings: .init(),
            snippets: .init(
                configuration: configuration,
                snippets: snippets,
                preloadedResources: preloadedResources,
                socketURL: socketURL
            ),
            universalLinks: .init()
        )

        let storage = state.snippets.snippets.map(\.snippet)
        logger.info(
            "\(storage.count) \(storage.count == 1 ? "snippet" : "snippets") loaded from disk"
        )

        let publisher = PassthroughSubject<TWSStreamEvent, Never>()
        let mainReducer = MainReducer(publisher: publisher)

        let combinedReducers = CombineReducers {
            mainReducer
                .onChange(of: \.snippets.snippets) { _, newValue in
                    Reduce { _, _ in
                        let newSnippets = newValue.map(\.snippet)
                        let onlyEnabledSnippets = newSnippets.filter { snippet in
                            return TWSSnippet.SnippetStatus(snippetStatus: snippet.status) == .enabled
                        }
                        return .send(.snippetsDidChange(onlyEnabledSnippets))
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

        let manager = TWSManager(store: store, observer: publisher.eraseToAnyPublisher(), configuration: configuration)
        logger.info("Created a new TWSManager for configuration: \(configuration)")
        _instances[configuration] = WeakBox(manager)
        return manager
    }
}
