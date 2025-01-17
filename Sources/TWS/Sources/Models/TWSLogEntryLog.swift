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
import OSLog

/// A struct representing a log entry for display purposes.
///
/// This struct encapsulates information about a log entry, including the date of the log, its category, and the composed message. It is designed to provide a user-friendly representation of logs, extracted from an `OSLogEntryLog` instance.
public struct TWSLogEntryLog: Sendable {

    /// The date and time when the log entry was created.
    public let date: Date

    /// The category associated with the log entry.
    public let category: String

    /// The full message composed from the log entry.
    public let composedMessage: String

    init(from log: OSLogEntryLog) {
        date = log.date
        category = log.category
        composedMessage = log.composedMessage
    }
}
