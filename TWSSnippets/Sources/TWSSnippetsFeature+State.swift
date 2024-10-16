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
        @Shared public internal(set) var source: TWSSource
        @Shared public internal(set) var preloadedResources: [TWSSnippet.Attachment: String]
        @Shared public var snippetDates: [UUID: SnippetDateInfo]
        public internal(set) var socketURL: URL?
        public internal(set) var isSocketConnected = false

        public init(
            configuration: TWSConfiguration,
            snippets: [TWSSnippet]? = nil,
            preloadedResources: [TWSSnippet.Attachment: String]? = nil,
            socketURL: URL? = nil,
            serverTime: Date? = nil
        ) {
            _snippets = Shared(wrappedValue: [], .snippets(for: configuration))
            _source = Shared(wrappedValue: .api, .source(for: configuration))
            _preloadedResources = Shared(wrappedValue: [:], .resources(for: configuration))
            _snippetDates = Shared(wrappedValue: [:], .snippetDates(for: configuration))

            if let snippets {
                var state = [TWSSnippetFeature.State]()
                snippets.forEach { snippet in
                    if let serverTime {
                        snippetDates[snippet.id] = SnippetDateInfo(serverTime: serverTime)
                    }
                    state.append(TWSSnippetFeature.State.init(snippet: snippet))
                }
                self.snippets = .init(uniqueElements: state)
            }

            if let socketURL {
                self.socketURL = socketURL
            }

            if let preloadedResources {
                self.preloadedResources = preloadedResources
            }
        }
    }
}

public struct SnippetDateInfo: Equatable, Codable, Sendable {
    let serverTime: Date
    let phoneTime: Date
    public var adaptedTime: Date {
        serverTime.addingTimeInterval(getElapsedSecondsSinceLastUpdate())
    }

    init(serverTime: Date) {
        @Dependency(\.date) var date
        self.serverTime = serverTime
        self.phoneTime = date.now
    }

    private func getElapsedSecondsSinceLastUpdate() -> TimeInterval {
        @Dependency(\.date) var date
        return date.now.timeIntervalSince(phoneTime)
    }
}
