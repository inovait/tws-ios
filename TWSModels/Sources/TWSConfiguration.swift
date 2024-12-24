//
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
