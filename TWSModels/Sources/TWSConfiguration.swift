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
public protocol TWSConfiguration: Equatable, Hashable, Sendable {
    var id: String { get set }
}

public struct TWSBasicConfiguration: TWSConfiguration, Equatable {
    public var id: String
    public init(id: String) {
        self.id = id
    }
}

public struct TWSSharedConfiguration: TWSConfiguration, Equatable {
    public var id: String
    public init(id: String) {
        self.id = id
    }
}
