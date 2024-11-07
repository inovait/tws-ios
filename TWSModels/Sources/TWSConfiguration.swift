//
//  TWSConfiguration.swift
//  TWSKit
//
//  Created by Miha Hozjan on 17. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// A struct used to provided all information for a TWSKit manager to receive snippets and connect to the socket for updats
public struct TWSConfiguration: Hashable, Sendable {

    /// The ID of the TWS organization
    public let organizationID: String

    /// The ID of the TWS project
    public let projectID: String

    /// Initializes a new configuration
    /// - Parameters:
    ///   - organizationID: A valid UUID of the TWS organization.
    ///   - projectID: A valid UUID of the TWS project.
    public init(
        organizationID: String,
        projectID: String
    ) {
        self.organizationID = organizationID
        self.projectID = projectID
    }
}
