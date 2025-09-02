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

/// A protocol that represents a configuration required by ``TWSManager`` to retrieve snippets and establish a socket connection for updates.
public protocol TWSConfiguration: Equatable, Hashable, Sendable {
    var id: String { get }
}

/// A configuration type that enables ``TWSManager`` to fetch all snippets associated with a specific project ID. A valid tws-service.json file is required.
public struct TWSBasicConfiguration: TWSConfiguration, Equatable {
    public let id: String
    public init(id: String) {
        self.id = id
    }
}
