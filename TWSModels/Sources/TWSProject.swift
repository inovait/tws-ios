//
//  TWSProject.swift
//  TWSModels
//
//  Created by Miha Hozjan on 23. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// Details about the TWS project, including the WebSocket URL for listening to changes, code snippets, organizational information, and more.
@_documentation(visibility: internal)
public struct TWSProject: Codable, Equatable, Sendable {

    /// A socket used to listen for changes, such as snippet being modified, deleted or added
    public let listenOn: URL

    /// Array of snippets bind to the project
    public let snippets: [TWSSnippet]

    public init(
        listenOn: URL,
        snippets: [TWSSnippet]
    ) {
        self.listenOn = listenOn
        self.snippets = snippets
    }
}
