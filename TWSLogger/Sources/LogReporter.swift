//
//  LogBuffer.swift
//  TWSLogger
//
//  Created by Luka Kit on 4. 6. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import OSLog
import TWSModels

public struct LogReporter {

    public init() {}

    public func generateReport(
        bundleId: String,
        date: Date,
        reportFiltering: (OSLogEntryLog) -> String
    ) async throws -> URL? {
        let fileURL = try await openFile(fileName: "TWS-Logs.txt")
        if let fileURL {
            let filteredEntries = try await getLogsFromLogStore(bundleId: bundleId, date: date)
            if let filteredEntries {
                try parseLogsAndWriteToFile(filteredEntries, reportFiltering, fileURL)
            } else {
                throw LoggerError.unableToGetLogs
            }
            return fileURL
        } else {
            throw LoggerError.unableToCreateLogFile
        }
    }

    func getLogsFromLogStore(bundleId: String, date: Date) async throws -> [OSLogEntryLog]? {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(date: Calendar.current.startOfDay(for: date))
        let entries = try store.getEntries(at: position)

        let filteredEntries = entries
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.subsystem == bundleId }

        return filteredEntries
    }

    func parseLogsAndWriteToFile(
        _ logEntries: [OSLogEntryLog],
        _ reportFiltering: (OSLogEntryLog) -> String,
        _ fileURL: URL
    ) throws {
        if let fileHandle = FileHandle(forUpdatingAtPath: fileURL.path()) {
            try logEntries.forEach { entry in
                guard let data = ("\(reportFiltering(entry))\n").data(using: .utf8) else {
                    throw LoggerError.logContentCantBeParsed
                }
                try fileHandle.write(contentsOf: data)
            }
            try fileHandle.close()
        } else {
            throw LoggerError.unableToCreateLogFile
        }
    }

    func openFile(fileName: String) async throws -> URL? {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(for: .documentDirectory,
            in: .userDomainMask, appropriateFor: nil, create: false)
        let fileURL = documentsURL.appendingPathComponent(fileName)
        fileManager.createFile(atPath: fileURL.path(), contents: nil)
        return fileURL
    }
}
