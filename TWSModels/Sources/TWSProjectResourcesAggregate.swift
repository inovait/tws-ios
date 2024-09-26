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
public struct TWSProjectResourcesAggregate: Codable, Equatable {

    public let project: TWSProject
    public let jsResources: [URL: TWSRawJS]
    public let cssResources: [URL: TWSRawCSS]

    public init(
        project: TWSProject,
        jsResources: [URL: TWSRawJS],
        cssResources: [URL: TWSRawCSS]
    ) {
        self.project = project
        self.jsResources = jsResources
        self.cssResources = cssResources
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
        jsResources = [:]
        cssResources = [:]
    }
    #endif

    public subscript<T>(dynamicMember keyPath: KeyPath<TWSProject, T>) -> T {
        project[keyPath: keyPath]
    }
}
