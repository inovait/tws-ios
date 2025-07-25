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
@_spi(Internals) import TWSModels
internal import ComposableArchitecture
internal import TWSSnippet

class CampaignPresenter: TWSPresenter {
    private weak var manager: TWSManager?
    
    init(manager: TWSManager) {
        self.manager = manager
    }
    
    var preloadedResources: [TWSSnippet.Attachment : ResourceResponse] {
        manager?.store.snippets.preloadedCampaignResources ?? [:]
    }
    
    var navigationProvider: any NavigationProvider {
        guard let navigationProvider = manager?.navigationProvider
        else { preconditionFailure("Manager is nil at the time of navigation provider access.") }
        return navigationProvider
    }
    
    var heightProvider: any SnippetHeightProvider {
        guard let snippetHeightProvider = manager?.snippetHeightProvider
        else { preconditionFailure("Manager is nil at the time of height provider access.") }
        return snippetHeightProvider
    }
    
    func isVisible(snippet: TWSSnippet) -> Bool {
        manager?.store.snippets.campaignSnippets[id: snippet.id]?.isVisible ?? false
    }
    
    func resourcesHash(for snippet: TWSSnippet) -> Int {
        _resourcesHash(resources: manager?.store.snippets.preloadedCampaignResources, of: snippet)
    }
    
    func handleIncomingUrl(_ url: URL) {
        manager?.handleIncomingUrl(url)
    }
    
    func store(forSnippetID id: String) -> StoreOf<TWSSnippetFeature>? {
        manager?.store.scope(
            state: \.snippets.campaignSnippets[id: id],
            action: \.snippets.business.campaignSnippets[id: id]
        )
    }
    
    // MARK: - Helper methods

    private func _resourcesHash(
        resources: [TWSSnippet.Attachment: ResourceResponse]?,
        of snippet: TWSSnippet
    ) -> Int {
        let resources = resources ?? [:]
        var hasher = Hasher()
        snippet.dynamicResources?.forEach { hasher.combine(resources[$0]?.data) }
        return hasher.finalize()
    }
}
