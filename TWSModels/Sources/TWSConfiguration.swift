//
//  TWSConfiguration.swift
//  TWSKit
//
//  Created by Miha Hozjan on 17. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

/// A struct used to provided all information for a TWSKit manager to receive snippets and connect to the socket for updats
public struct TWSConfiguration: Hashable {

    /// The ID of the TWS organization
    public let organizationID: UUID

    /// The ID of the TWS project
    public let projectID: UUID

    /// Initializes a new configuration
    /// - Parameters:
    ///   - organizationID: A valid UUID of the TWS organization.
    ///   - projectID: A valid UUID of the TWS project.
    public init(
        organizationID: String,
        projectID: String
    ) {
        guard let organizationID = UUID(uuidString: organizationID)
        else { preconditionFailure(
            "Invalid `organization ID`. It should be a valid UUID. Received: \(organizationID)"
        )}

        guard let projectID = UUID(uuidString: projectID)
        else { preconditionFailure(
            "Invalid `organization ID`. It should be a valid UUID. Received: \(projectID)"
        )}

        self.organizationID = organizationID
        self.projectID = projectID
    }
}
