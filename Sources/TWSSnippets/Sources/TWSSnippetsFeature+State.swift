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
import ComposableArchitecture
import TWSModels
import TWSSnippet
import Sharing
import TWSTriggers

extension TWSSnippetsFeature {

    @ObservableState
    public struct State: Equatable {

        #if TESTING
        // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
        public internal(set) var snippets: IdentifiedArrayOf<TWSSnippetFeature.State>
        #else
        @ObservationStateIgnored
        @Sharing.Shared public internal(set) var snippets: IdentifiedArrayOf<TWSSnippetFeature.State>
        #endif
        public internal(set) var campaignSnippets: IdentifiedArrayOf<TWSSnippetFeature.State>
        
        public internal(set) var preloadedCampaignResources: [TWSSnippet.Attachment: ResourceResponse]
        #if TESTING
        public internal(set) var preloadedResources: [TWSSnippet.Attachment: ResourceResponse]
        #else
        @ObservationStateIgnored

        @Sharing.Shared public internal(set) var preloadedResources: [TWSSnippet.Attachment: ResourceResponse]
        #endif
        
        @ObservationStateIgnored
        @Sharing.Shared public internal(set) var snippetDates: [TWSSnippet.ID: SnippetDateInfo]
        public internal(set) var socketURL: URL?
        public internal(set) var isSocketConnected = false
        public internal(set) var state: TWSLoadingState = .idle
        public internal(set) var campaigns: IdentifiedArrayOf<TWSTriggersFeature.State> = .init()
        public internal(set) var shouldTriggerSdkInitCampaign = true

        public init(
            configuration: any TWSConfiguration,
            snippets: [TWSSnippet]? = nil,
            preloadedResources: [TWSSnippet.Attachment: ResourceResponse]? = nil,
            socketURL: URL? = nil,
            serverTime: Date? = nil
        ) {
            self.campaignSnippets = .init()
            self.preloadedCampaignResources = [:]
            #if TESTING
            // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
            self.snippets = .init(
                uniqueElements: (snippets ?? []).map { .init(snippet: $0) }
            )
            self.preloadedResources = preloadedResources ?? [:]
            #else
            _snippets = Shared(wrappedValue: [], .snippets(for: configuration))
            _preloadedResources = Shared(wrappedValue: [:], .resources(for: configuration))
            #endif
            _snippetDates = Shared(wrappedValue: [:], .snippetDates(for: configuration))

            if let snippets {
                let state = snippets.map { TWSSnippetFeature.State(
                    snippet: $0
                )}

                if let serverTime {
                    snippets.forEach { snippet in
                        $snippetDates[snippet.id].withLock { $0 = SnippetDateInfo(serverTime: serverTime) }
                    }
                }

                #if TESTING
                // https://github.com/pointfreeco/swift-composable-architecture/discussions/3308
                self.snippets = .init(uniqueElements: state)
                #else
                self.$snippets.withLock { $0 = .init(uniqueElements: state) }
                #endif
            }

            state = self.snippets.isEmpty ? .idle : .loaded

            if let socketURL {
                self.socketURL = socketURL
            }

            if let preloadedResources {
                #if TESTING
                self.preloadedResources = preloadedResources
                #else
                self.$preloadedResources.withLock { $0 = preloadedResources }
                #endif
            }
        }
    }
}
