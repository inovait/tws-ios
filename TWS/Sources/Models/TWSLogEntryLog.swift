//
//  TWSLogEntryLog.swift
//  TWS
//
//  Created by Miha Hozjan on 2. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
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
