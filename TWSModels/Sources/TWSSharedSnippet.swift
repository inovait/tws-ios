//
//  TWSSharedSnippet.swift
//  TWSModels
//
//  Created by Miha Hozjan on 23. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// Information provided when a snippet is opened via universal link. It contains everything needed,
/// to start a new, separate, TWS flow
public struct TWSSharedSnippet: Codable, Equatable, Identifiable {

    /// Identifiable conformance
    public var id: String {
        "\(organization.id)~\(project.id)~\(snippet.id)"
    }

    /// The organization to which the snippet is bind to
    public let organization: Organization

    /// The project to which the snippet is bind to
    public let project: Project

    /// The snippet which was opened via universal link
    public let snippet: TWSSnippet

    /// The configuration for the presented snippet
    public var configuration: TWSConfiguration {
        .init(
            organizationID: organization.id,
            projectID: project.id
        )
    }
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
