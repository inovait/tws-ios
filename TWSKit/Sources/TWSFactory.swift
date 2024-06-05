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
@_implementationOnly import TWSCommon
@_implementationOnly import ComposableArchitecture

public class TWSFactory {

    public class func new() -> TWSManager {
        let stream = AsyncStream<[TWSSnippet]>.makeStream()
        let state = TWSCoreFeature.State(
            settings: .init(),
            snippets: .init()
        )

        let storage = state.snippets.snippets.map(\.snippet)
        print("\(storage.count) \(storage.count == 1 ? "snippet" : "snippets") loaded from disk", Date())

        let store = Store(
            initialState: state,
            reducer: {
                TWSCoreFeature()
                    .onChange(of: \.snippets.snippets) { _, newValue in
                        Reduce { _, _ in
                            stream.continuation.yield(newValue.map(\.snippet))
                            return .none
                        }
                    }
            }
        )

        stream.continuation.yield(storage)

        return TWSManager(store: store, stream: stream.stream)
    }
}
