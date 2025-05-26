////
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
import TWSModels
import TWSSnippet
import ComposableArchitecture


@MainActor
public final class TWSLocalManager {
    @Sharing.Shared var preloadedAssets: [TWSSnippet.Attachment: ResourceResponse]
    @Shared(.inMemory("localSnippets")) var localSnippets: [TWSSnippet: [TWSRawDynamicResource]] = [:]
    @Shared(.inMemory("snippetFeatures")) var snippetFeatures: [TWSSnippet.ID: StoreOf<TWSSnippetFeature>] = [:]
    
    public nonisolated init() {
        _preloadedAssets = Shared(wrappedValue: [:], .resources())
    }
    
    public func getPreloadedAssets() -> [TWSSnippet.Attachment: ResourceResponse] { preloadedAssets }
    
    public func saveLocalSnippet(_ snippet: TWSSnippet, withResources resources: [TWSRawDynamicResource]) {
        let _ = $localSnippets.withLock { $0.updateValue(resources, forKey: snippet)}
        let snippetFeature: StoreOf<TWSSnippetFeature> = .init(initialState: TWSSnippetFeature.State(snippet: snippet), reducer: { TWSSnippetFeature() })
        let _ = $snippetFeatures.withLock { $0.updateValue(snippetFeature, forKey: snippet.id) }
    }
    
    public func getSnippetFeature(id: TWSSnippet.ID) -> StoreOf<TWSSnippetFeature>? { snippetFeatures[id] }
    
    public func getSnippetFeatures() -> [TWSSnippet.ID: StoreOf<TWSSnippetFeature>] { snippetFeatures }
    
    public func updatePreloadedAssets(for key: TWSSnippet.Attachment, with: ResourceResponse) {
        $preloadedAssets.withLock { $0.updateValue(with, forKey: key)}
    }
    
}
