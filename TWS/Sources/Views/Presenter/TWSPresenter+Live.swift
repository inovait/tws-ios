//
//  TWSPresenter+Live.swift
//  Playground
//
//  Created by Miha Hozjan on 11. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
@_spi(Internals) import TWSModels
internal import ComposableArchitecture
internal import TWSSnippet

class LivePresenter: TWSPresenter {

    private weak var manager: TWSManager?

    init(manager: TWSManager) {
        self.manager = manager
    }

    // MARK: - Confirming to `TWSPresenter`

    var isLocal = false

    var preloadedResources: [TWSSnippet.Attachment: String] {
        manager?.store.snippets.preloadedResources ?? [:]
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

    //

    func isVisible(snippet: TWSSnippet) -> Bool {
        manager?.store.snippets.snippets[id: snippet.id]?.isVisible ?? false
    }

    func resourcesHash(for snippet: TWSSnippet) -> Int {
        _resourcesHash(resources: manager?.store.snippets.preloadedResources, of: snippet)
    }

    func updateCount(for snippet: TWSSnippet) -> Int {
        manager?.store.snippets.snippets[id: snippet.id]?.updateCount ?? 0
    }

    func handleIncomingUrl(_ url: URL) {
        manager?.handleIncomingUrl(url)
    }

    func store(forSnippetID id: String) -> StoreOf<TWSSnippetFeature>? {
        manager?.store.scope(
            state: \.snippets.snippets[id: id],
            action: \.snippets.business.snippets[id: id]
        )
    }

    // MARK: - Helper methods

    private func _resourcesHash(
        resources: [TWSSnippet.Attachment: String]?,
        of snippet: TWSSnippet
    ) -> Int {
        let resources = resources ?? [:]
        var hasher = Hasher()
        snippet.dynamicResources?.forEach { hasher.combine(resources[$0]) }
        return hasher.finalize()
    }
}
