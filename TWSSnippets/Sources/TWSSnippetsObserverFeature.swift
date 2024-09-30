//
//  TWSSnippetFeatureObserver.swift
//  TWSSnippets
//
//  Created by Miha Hozjan on 30. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct TWSSnippetsObserverFeature {

    public init() { }

    public var body: some ReducerOf<TWSSnippetsFeature> {
        TWSSnippetsFeature()
            .onChange(of: \.socketURL) { oldValue, newValue in
                Reduce { _, _ in
                    if oldValue != newValue && newValue != nil {
                        return .send(.business(.listenForChanges))
                    } else {
                        return .none
                    }
                }
            }
    }
}
