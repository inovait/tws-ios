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
internal import TWSSettings
internal import TWSSnippets
internal import TWSSnippet
internal import ComposableArchitecture
import TWSModels

/// # TWSFactory
///
/// A class responsible for initializing and managing instances of ``TWSManager``. It provides methods to create new instances of ``TWSManager`` with various configurations and ensures efficient memory management by reusing existing instances when possible.
@MainActor
public class TWSFactory {

    private static var _instances = ThreadSafeDictionary<String, WeakBox<TWSManager>>()

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
        with configuration: any TWSConfiguration
    ) -> TWSManager {
        _new(
            configuration: configuration,
            snippets: nil,
            preloadedResources: nil,
            socketURL: nil
        )
    }
    
    public class func get(
        with configuration: any TWSConfiguration
    ) -> TWSManager? {
        if let manager = _instances[configuration.id]?.box {
            logger.info("Reusing TWSManager for configuration: \(configuration)")
            return manager
        }
        return nil
    }

    // MARK: - Internal

    class func destroy(
        configuration: any TWSConfiguration
    ) {
        _instances.removeValue(forKey: configuration.id)

        Task { @MainActor in
            @Dependency(\.socket) var socket
            await socket.abort(configuration)
        }
    }

    // MARK: - Helpers

    private class func _new(
        configuration: any TWSConfiguration,
        snippets: [TWSSnippet]?,
        preloadedResources: [TWSSnippet.Attachment: ResourceResponse]?,
        socketURL: URL?
    ) -> TWSManager {
        if let manager = _instances[configuration.id]?.box {
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
        _instances[configuration.id] = WeakBox(manager)
        return manager
    }
}
