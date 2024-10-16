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
    @_spi(InternalLibraries) public let resources: [TWSSnippet.Attachment: String]

    public init(
        project: TWSProject,
        resources: [TWSSnippet.Attachment: String]
    ) {
        self.project = project
        self.resources = resources
    }

    #if DEBUG
    // Used in test
    public init(
        listenOn: URL,
        snippets: [TWSSnippet]
    ) {
        project = .init(
            listenOn: listenOn,
            snippets: snippets
        )
        resources = [:]
    }
    #endif

    public subscript<T>(dynamicMember keyPath: KeyPath<TWSProject, T>) -> T {
        project[keyPath: keyPath]
    }
}
