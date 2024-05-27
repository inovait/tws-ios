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
        let stream = AsyncStream<[TWSSnippet]>.makeStream()
        let store = Store(
            initialState: TWSCoreFeature.State(
                settings: .init(),
                snippets: .init(snippets: [])
            ),
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

        return TWSManager(store: store, stream: stream.stream)
    }
}
