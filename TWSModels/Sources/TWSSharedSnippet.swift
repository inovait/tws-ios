//
//  TWSSharedSnippet.swift
//  TWSModels
//
//  Created by Miha Hozjan on 23. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// Information provided when a snippet si opened via univarsal link. It contains everything needed,
/// to start a new, separate, TWS flow
public struct TWSSharedSnippet: Codable, Equatable {

    /// The organization to which the snippet is bind to
    public let organization: Organization

    /// The project to which the snippet is bind to
    public let project: Project

    /// The snippet which was opened via universal link
    public let snippet: TWSSnippet
}

public extension TWSSharedSnippet {

    /// TWS project's information
    struct Project: Codable, Equatable {

        /// The ID of the TWS project
        public let id: String
    }

    /// TWS organization's information
    struct Organization: Codable, Equatable {

        /// The ID of the TWS organization
        public let id: String
    }
}
