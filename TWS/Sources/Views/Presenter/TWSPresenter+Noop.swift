//
//  TWSPresenter+Noop.swift
//  Playground
//
//  Created by Miha Hozjan on 11. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
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
