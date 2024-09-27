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
public struct TWSSharedSnippetResourcesAggregate: Codable, Equatable {

    public let sharedSnippet: TWSSharedSnippet
    public let resources: [TWSSnippet.Attachment: String]

    public init(
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

