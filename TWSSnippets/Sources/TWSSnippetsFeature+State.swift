//
//  TWSSnippetsFeature+State.swift
//  TWSSnippets
//
//  Created by Miha Hozjan on 30. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import ComposableArchitecture
import TWSModels
import TWSSnippet

extension TWSSnippetsFeature {

    @ObservableState
    public struct State: Equatable {

        @Shared public internal(set) var snippets: IdentifiedArrayOf<TWSSnippetFeature.State>
        @Shared public internal(set) var preloadedResources: [TWSSnippet.Attachment: String]
        @Shared public internal(set) var snippetDates: [TWSSnippet.ID: SnippetDateInfo]
        public internal(set) var socketURL: URL?
        public internal(set) var isSocketConnected = false
        public internal(set) var state: TWSLoadingState = .idle

        public init(
            configuration: TWSConfiguration,
            snippets: [TWSSnippet]? = nil,
            preloadedResources: [TWSSnippet.Attachment: String]? = nil,
            socketURL: URL? = nil,
            serverTime: Date? = nil
        ) {
            _snippets = Shared(wrappedValue: [], .snippets(for: configuration))
            _preloadedResources = Shared(wrappedValue: [:], .resources(for: configuration))
            _snippetDates = Shared(wrappedValue: [:], .snippetDates(for: configuration))

            if let snippets {
                let state = snippets.map({ TWSSnippetFeature.State.init(snippet: $0) })
                if let serverTime {
                    snippets.forEach { snippet in
                        snippetDates[snippet.id] = SnippetDateInfo(serverTime: serverTime)
                    }
                }
                self.snippets = .init(uniqueElements: state)
            }

            state = self.snippets.isEmpty ? .idle : .loaded

            if let socketURL {
                self.socketURL = socketURL
            }

            if let preloadedResources {
                self.preloadedResources = preloadedResources
            }
        }
    }
}
