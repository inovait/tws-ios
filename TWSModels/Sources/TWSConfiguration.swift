//
//  TWSConfiguration.swift
//  TWS
//
//  Created by Miha Hozjan on 17. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// A struct that provides all the necessary information for a ``TWSManager`` to retrieve snippets and establish a socket connection for updates.
public struct TWSConfiguration: Hashable, Sendable {

    /// The unique identifier of the TWS organization.
    public let organizationID: String

    /// The unique identifier of the TWS project.
    public let projectID: String

    // MARK: - Initializer

    /// Initializes a new ``TWSConfiguration`` with the provided organization and project IDs.
    ///
    /// - Parameters:
    ///   - organizationID: An ID representing the TWS organization.
    ///   - projectID: An ID representing the TWS project.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let config = TWSConfiguration(
    ///     organizationID: "<ORGANIZATION_ID>",
    ///     projectID: "<PROJECT_ID>"
    /// )
    /// ```
    /// This example demonstrates how to create a configuration for a specific organization and project.
    public init(
        organizationID: String,
        projectID: String
    ) {
        self.organizationID = organizationID
        self.projectID = projectID
    }
}
