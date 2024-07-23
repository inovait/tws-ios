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
    public var getProject: @Sendable (TWSConfiguration) async throws -> TWSProject
    public var getSocket: @Sendable (TWSConfiguration) async throws -> URL
    public var getSnippetById: @Sendable (TWSConfiguration, _ snippetId: UUID) async throws -> TWSSnippet
}

public enum APIDependencyKey: DependencyKey {

    public static var liveValue: APIDependency {
        let api = TWSAPIFactory.new(host: "api.thewebsnippet.dev")

        return .init(
            getProject: api.getProject,
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
