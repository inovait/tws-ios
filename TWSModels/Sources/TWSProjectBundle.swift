//
//  TWSProjectResourcesAggregate.swift
//  TWSModels
//
//  Created by Miha Hozjan on 26. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// An aggregate of an project and all associated resources
@dynamicMemberLookup
public struct TWSProjectBundle: Codable, Equatable, Sendable {

    public let project: TWSProject
    @_spi(Internals) public let serverDate: Date?

    public init(
        project: TWSProject,
        serverDate: Date? = nil
    ) {
        self.project = project
        self.serverDate = serverDate
    }

    #if DEBUG
    // Used in test
    public init(
        listenOn: URL,
        snippets: [TWSSnippet],
        date: Date? = nil
    ) {
        project = .init(
            listenOn: listenOn,
            snippets: snippets
        )
        serverDate = date
    }
    #endif

    public subscript<T>(dynamicMember keyPath: KeyPath<TWSProject, T>) -> T {
        project[keyPath: keyPath]
    }
}
