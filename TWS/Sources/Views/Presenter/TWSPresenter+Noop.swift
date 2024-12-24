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
import TWSModels
internal import ComposableArchitecture
internal import TWSSnippet

class NoopPresenter: TWSPresenter {

    private let _heightProvider = SnippetHeightProviderImpl()
    private let _navigationProvider = NavigationProviderImpl()

    // MARK: - Confirming to `TWSPresenter`

    var preloadedResources: [TWSSnippet.Attachment: String] { [:] }
    var heightProvider: SnippetHeightProvider { _heightProvider }
    var navigationProvider: NavigationProvider { _navigationProvider }
    var isLocal = true

    func isVisible(snippet _: TWSSnippet) -> Bool { true }
    func resourcesHash(for _: TWSSnippet) -> Int { 0 }
    func updateCount(for snippet: TWSSnippet) -> Int { 0 }
    func handleIncomingUrl(_ url: URL) { }
    func store(forSnippetID id: String) -> StoreOf<TWSSnippetFeature>? { nil }
}
