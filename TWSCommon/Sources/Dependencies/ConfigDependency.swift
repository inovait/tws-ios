//
//  ConfigDependency.swift
//  TWSKit
//
//  Created by Miha Hozjan on 17. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels
import ComposableArchitecture

public struct ConfigDependency {

    public var configuration: @Sendable () -> TWSConfiguration

    public func callAsFunction() -> TWSConfiguration {
        configuration()
    }
}

public enum ConfigDependencyKey: DependencyKey {

    public static var liveValue: ConfigDependency {
        .init(
            configuration: { preconditionFailure("Configuration dependency was not overridden") }
        )
    }

    public static var testValue: ConfigDependency {
        .init(configuration: { .init(organizationID: "abc", projectID: "123") })
    }
}

public extension DependencyValues {

    var configuration: ConfigDependency {
        get { self[ConfigDependencyKey.self] }
        set { self[ConfigDependencyKey.self] = newValue }
    }
}
