//
//  APIDependency.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels
import TWSAPI
import ComposableArchitecture

public struct APIDependency {
    public var getSnippets: @Sendable () async throws -> [TWSSnippet]
    public var getSocket: @Sendable () async throws -> URL
    public var getSnippetById: @Sendable (_ snippetId: String) async throws -> TWSSnippet
}

public enum APIDependencyKey: DependencyKey {

    public static var liveValue: APIDependency {
        let api = TWSAPIFactory.new(host: "api.thewebsnippet.dev")

        return .init(
            getSnippets: api.getSnippets,
            getSocket: api.getSocket,
            getSnippetById: api.getSnippetById
        )
    }
}

public extension DependencyValues {

    var api: APIDependency {
        get { self[APIDependencyKey.self] }
        set { self[APIDependencyKey.self] = newValue }
    }
}
