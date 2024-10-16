//
//  TWSLoggerError.swift
//  TWSLogger
//
//  Created by Luka Kit on 13. 6. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public enum LoggerError: Error, Sendable {
    case bundleIdNotAvailable
    case unableToGetLogs
    case unableToCreateLogFile
    case logContentCantBeParsed
}
