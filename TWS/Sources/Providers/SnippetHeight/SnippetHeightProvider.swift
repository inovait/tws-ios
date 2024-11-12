//
//  HeightProvider.swift
//  TWSAPI
//
//  Created by Miha Hozjan on 24. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import UIKit

@MainActor
protocol SnippetHeightProvider {

    func set(height: CGFloat, for hash: WebPageDescription, displayID: String)
    func getHeight(for hash: WebPageDescription, displayID: String) -> CGFloat?
    func reset()
}

class SnippetHeightProviderImpl: SnippetHeightProvider {

    private var store = [WebPageDescription: [String: CGFloat]]()

    // MARK: - Confirming to `SnippetHeightProvider`

    func set(height: CGFloat, for hash: WebPageDescription, displayID: String) {
        logger.debug("Set h(\(height)) for \(hash.path)@\(displayID)")
        store[hash, default: [:]][displayID] = height
    }

    func getHeight(for hash: WebPageDescription, displayID: String) -> CGFloat? {
        logger.debug("Get h(\(store[hash]?[displayID] ?? -1)) for \(hash.path)@\(displayID)")
        return store[hash]?[displayID]
    }

    func reset() {
        logger.debug("Reset store")
        store.removeAll()
    }
}
