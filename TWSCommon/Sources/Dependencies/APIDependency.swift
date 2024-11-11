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

@DependencyClient
public struct APIDependency: Sendable {

    public var getProject: @Sendable (
        TWSConfiguration
    ) async throws(APIError) -> (TWSProject, Date?) = { _ throws(APIError) in
        reportIssue("\(Self.self).getProject")
        throw APIError.local(NSError(domain: "", code: -1))
    }

    public var getSnippetBySharedId: @Sendable (
        TWSConfiguration,
        _ snippetId: String
    ) async throws(APIError) -> TWSSharedSnippet = { _, _ throws(APIError) in
        reportIssue("\(Self.self).getSnippetBySharedId")
        throw APIError.local(NSError(domain: "", code: -1))
    }

    public var getResource: @Sendable (
        TWSSnippet.Attachment, [String:String]
    ) async throws(APIError) -> String = { _, _ throws(APIError) in
        reportIssue("\(Self.self).loadResource")
        throw APIError.local(NSError(domain: "", code: -1))
    }
}

public enum APIDependencyKey: DependencyKey {

    public static var liveValue: APIDependency {
        let api = TWSAPIFactory.new(host: "api.thewebsnippet.dev")

        return .init(
            getProject: api.getProject,
            getSnippetBySharedId: api.getSnippetBySharedId,
            getResource: api.getResource
        )
    }
}

public extension DependencyValues {

    var api: APIDependency {
        get { self[APIDependencyKey.self] }
        set { self[APIDependencyKey.self] = newValue }
    }
}
