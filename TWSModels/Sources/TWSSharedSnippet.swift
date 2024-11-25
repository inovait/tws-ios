//
//  TWSSharedSnippet.swift
//  TWSModels
//
//  Created by Miha Hozjan on 23. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// Information provided when a snippet is opened via a universal link.
///
/// This struct contains all the necessary data to start a new, separate TWS flow, including organization, project, and snippet details.
public struct TWSSharedSnippet: Codable, Equatable, Identifiable, Sendable {

    /// A unique identifier for the shared snippet, derived from the organization, project, and snippet IDs.
    public var id: String {
        "\(organization.id)~\(project.id)~\(snippet.id)"
    }

    /// The organization to which the snippet is bound.
    public let organization: Organization

    /// The project to which the snippet is bound.
    public let project: Project

    /// The snippet that was opened via the universal link.
    public let snippet: TWSSnippet

    /// The configuration for the presented snippet, derived from the organization and project IDs.
    public var configuration: TWSConfiguration {
        .init(
            organizationID: organization.id,
            projectID: project.id
        )
    }
}

public extension TWSSharedSnippet {

    /// TWS project's information.
    struct Project: Codable, Equatable, Sendable {

        /// The ID of the TWS project.
        public let id: String
    }

    /// TWS organization's information.
    struct Organization: Codable, Equatable, Sendable {

        /// The ID of the TWS organization.
        public let id: String
    }
}
