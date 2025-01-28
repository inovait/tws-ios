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

/// Information provided when a snippet is opened via a universal link.
///
/// This struct contains all the necessary data to start a new, separate TWS flow, including project and snippet details.
public struct TWSSharedSnippet: Codable, Equatable, Identifiable, Sendable {

    /// A unique identifier for the shared snippet, derived from the  project, and snippet IDs.
    public var id: String {
        "\(project.id)~\(snippet.id)"
    }
    /// The project to which the snippet is bound.
    public let project: Project

    /// The snippet that was opened via the universal link.
    public let snippet: TWSSnippet

}

public extension TWSSharedSnippet {

    /// TWS project's information.
    struct Project: Codable, Equatable, Sendable {

        /// The ID of the TWS project.
        public let id: String
    }
}
