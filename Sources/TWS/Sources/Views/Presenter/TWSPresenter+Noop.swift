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
@_spi(Internals) import TWSModels
internal import ComposableArchitecture
internal import TWSSnippet
import TWSLocal


class NoopPresenter: TWSPresenter {
    private let _heightProvider = SnippetHeightProviderImpl()
    private let _navigationProvider = NavigationProviderImpl()

    // MARK: - Confirming to `TWSPresenter`
    var heightProvider: SnippetHeightProvider { _heightProvider }
    var navigationProvider: NavigationProvider { _navigationProvider }

    func preloadedResource(forSnippetID id: String) -> ResourceResponse? {
        store(forSnippetID: id)?.htmlContent
    }
    
    func isVisible(snippet _: TWSSnippet) -> Bool { true }
    func resourceHash(for snippet: TWSSnippet) -> Int {
        hashResources(resources: store(forSnippetID: snippet.id)?.htmlContent, snippet: snippet)
    }
    
    func handleIncomingUrl(_ url: URL) { }
    func store(forSnippetID id: String) -> StoreOf<TWSSnippetFeature>? { TWSLocalSnippetsManager.store(for: id) }
    
    func saveLocalSnippet(_ snippet: TWSSnippet) {
        TWSLocalSnippetsManager.saveLocalSnippet(snippet)
    }
    
    private func hashResources(
        resources: ResourceResponse?,
        snippet: TWSSnippet
    ) -> Int {
        var hasher = Hasher()
        hasher.combine(resources)
        return hasher.finalize()
    }
}
