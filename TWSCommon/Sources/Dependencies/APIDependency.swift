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
}

public enum APIDependencyKey: DependencyKey {

    public static var liveValue: APIDependency {
        let api = TWSAPIFactory.new(host: "websnippet20240506104155.azurewebsites.net")

        return .init(
            getSnippets: api.getSnippets
        )
    }
}

public extension DependencyValues {

    var api: APIDependency {
        get { self[APIDependencyKey.self] }
        set { self[APIDependencyKey.self] = newValue }
    }
}
