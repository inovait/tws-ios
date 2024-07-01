//
//  TWSFactory.swift
//  TWSKit
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels
@_implementationOnly import TWSCore
@_implementationOnly import TWSSettings
@_implementationOnly import TWSSnippets
@_implementationOnly import ComposableArchitecture

public class TWSFactory {

    public class func new() -> TWSManager {
        let snippetsStream = AsyncStream<[TWSSnippet]>.makeStream()
        let qrSnippetStream = AsyncStream<TWSSnippet?>.makeStream()
        let state = TWSCoreFeature.State(
            settings: .init(),
            snippets: .init(),
            universalLinks: .init()
        )

        let storage = state.snippets.snippets.map(\.snippet)
        logger.info(
            "\(storage.count) \(storage.count == 1 ? "snippet" : "snippets") loaded from disk"
        )

        let store = Store(
            initialState: state,
            reducer: {
                TWSCoreFeature()
                    .onChange(of: \.snippets.snippets) { _, newValue in
                        Reduce { _, _ in
                            snippetsStream.continuation.yield(newValue.map(\.snippet))
                            return .none
                        }
                    }
                    .onChange(of: \.universalLinks.loadedSnippet) { _, newValue in
                        Reduce { _, _ in
                            qrSnippetStream.continuation.yield(newValue)
                            return .none
                        }
                    }
            }
        )

        snippetsStream.continuation.yield(storage)

        return TWSManager(store: store, snippetsStream: snippetsStream.stream, qrSnippetStream: qrSnippetStream.stream)
    }
}
