//
//  TWSFactory.swift
//  TWS
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

/// # TWSFactory
///
/// A class responsible for initializing and managing instances of ``TWSManager``. It provides methods to create new instances of ``TWSManager`` with various configurations and ensures efficient memory management by reusing existing instances when possible.
@MainActor
public class TWSFactory {

    private static var _instances = ThreadSafeDictionary<TWSConfiguration, WeakBox<TWSManager>>()

    /// Creates and returns a new instance of ``TWSManager``.
    ///
    /// This method initializes a ``TWSManager`` with a specific project configuration, allowing you to manage and display snippets for that project.
    ///
    /// - Parameter configuration: The configuration for the project to initialize the manager.
    /// - Returns: An instance of ``TWSManager``.
    ///
    /// Example:
    /// ```swift
    /// let manager = TWSFactory.new(with: myConfiguration)
    /// ```
    public class func new(
        with configuration: TWSConfiguration
    ) -> TWSManager {
        _new(
            configuration: configuration,
            snippets: nil,
            preloadedResources: nil,
            socketURL: nil
        )
    }

    /// Creates and returns a new instance of ``TWSManager`` using shared snippet information.
    ///
    /// This method is typically used when handling a universal link that contains snippet data, enabling a seamless experience for handling deep links.
    ///
    /// - Parameter shared: Information about the snippet opened via a universal link.
    /// - Returns: An instance of ``TWSManager``.
    ///
    /// ```swift
    /// let manager = TWSFactory.new(with: sharedSnippet)
    /// ```
    ///
    /// ## Reacting to Universal Links
    ///
    /// When a universal link is received, you can use this helper method to create a new flow for TWS. Here’s an example implementation:
    ///
    /// ```swift
    /// struct HomeView: View {
    ///
    ///    @Environment(TWSManager.self) var tws
    ///    @State private var sharedSnippet: TWSSharedSnippet?
    ///
    ///    var body: some View {
    ///        TabView {
    ///            // Your main content
    ///        }
    ///        .task {
    ///            // 1. Observe events triggered by universal links
    ///            await tws.observe { event in
    ///                switch event {
    ///                case let .universalLinkSnippetLoaded(snippet):
    ///                    sharedSnippet = snippet
    ///
    ///                case .snippetsUpdated, .stateChanged:
    ///                    break
    ///
    ///                @unknown default:
    ///                    break
    ///                }
    ///            }
    ///        }
    ///        .sheet(item: $sharedSnippet) {
    ///            // 2. Use a helper method to create a ``TWSManager`` instance for the snippet and present it
    ///            TWSView(snippet: $0.snippet)
    ///                .twsEnable(sharedSnippet: $0)
    ///        }
    ///    }
    /// }

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
        preloadedResources: [TWSSnippet.Attachment: String]?,
        socketURL: URL?
    ) -> TWSManager {
        if let manager = _instances[configuration]?.box {
            logger.info("Reusing TWSManager for configuration: \(configuration)")
            return manager
        }

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

        let resourcesCount = state.snippets.preloadedResources.count
        logger.info(
            "\(resourcesCount) \(resourcesCount == 1 ? "resource" : "resources")"
        )

        let publisher = PassthroughSubject<TWSStreamEvent, Never>()
        let mainReducer = MainReducer(publisher: publisher)

        let combinedReducers = CombineReducers {
            mainReducer
                .onChange(of: \.snippets.snippets) { _, _ in
                    Reduce { _, _ in
                        return .send(.snippetsDidChange)
                    }
                }
                .onChange(of: \.snippets.state) { _, _ in
                    Reduce { _, _ in
                        return .send(.stateChanged)
                    }
                }
        }
        // Set the environment
        .dependency(\.configuration.configuration, { configuration })

        let store = Store(
            initialState: state,
            reducer: { combinedReducers }
        )

        let manager = TWSManager(
            store: store,
            observer: publisher
                // This is a 'must' we need to hop the thread for the store to set (if the user access it)
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher(),
            configuration: configuration
        )
        logger.info("Created a new TWSManager for configuration: \(configuration)")
        _instances[configuration] = WeakBox(manager)
        return manager
    }
}
