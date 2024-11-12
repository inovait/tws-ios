//
//  TWSLogEntryLog.swift
//  TWS
//
//  Created by Miha Hozjan on 2. 07. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import OSLog

/// A struct used to display logs
public struct TWSLogEntryLog: Sendable {

    public let date: Date
    public let category: String
    public let composedMessage: String

    init(from log: OSLogEntryLog) {
        date = log.date
        category = log.category
        composedMessage = log.composedMessage
    }
}
