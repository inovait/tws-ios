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

/// An aggregate of an project and all associated resources
@_documentation(visibility: internal)
@dynamicMemberLookup
public struct TWSProjectBundle: Codable, Equatable, Sendable {

    public let project: TWSProject
    @_spi(Internals) public let serverDate: Date?

    public init(
        project: TWSProject,
        serverDate: Date? = nil
    ) {
        self.project = project
        self.serverDate = serverDate
    }

    #if DEBUG
    // Used in test
    public init(
        listenOn: URL,
        snippets: [TWSSnippet],
        date: Date? = nil
    ) {
        project = .init(
            listenOn: listenOn,
            snippets: snippets
        )
        serverDate = date
    }
    #endif

    public subscript<T>(dynamicMember keyPath: KeyPath<TWSProject, T>) -> T {
        project[keyPath: keyPath]
    }
}
