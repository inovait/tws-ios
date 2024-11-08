//
//  TWSSharedSnippetResourcesAggregate.swift
//  TWSModels
//
//  Created by Miha Hozjan on 27. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// An aggregate of an sharedSnippet and all associated resources
@dynamicMemberLookup
public struct TWSSharedSnippetBundle: Codable, Equatable, Sendable {

    public let sharedSnippet: TWSSharedSnippet
    @_spi(Internals) public let resources: [TWSSnippet.Attachment: String]

    @_spi(Internals) public init(
        sharedSnippet: TWSSharedSnippet,
        resources: [TWSSnippet.Attachment: String]
    ) {
        self.sharedSnippet = sharedSnippet
        self.resources = resources
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<TWSSharedSnippet, T>) -> T {
        sharedSnippet[keyPath: keyPath]
    }
}
