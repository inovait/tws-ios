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

    public static func generateReport(
        bundleId: String, reportFiltering: (OSLogEntryLog) -> String) async throws -> URL? {
        let filteredEntries = try await getLogsFromLogStore(bundleId: bundleId)
        if let filteredEntries {
            let report = parseLogsToString(filteredEntries, reportFiltering)
            return try await FileHelper.saveReport(report, fileName: "TWS-Logs-\(Date().description).txt")
        }
        throw LoggerError.unableToGetLogs
    }

    static func getLogsFromLogStore(bundleId: String) async throws -> [OSLogEntryLog]? {
        let begginingOfFromDate = Calendar.current.startOfDay(for: Date())

        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(date: Calendar.current.startOfDay(for: begginingOfFromDate))
        let entries = try store.getEntries(at: position)

        let filteredEntries = entries
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.subsystem == bundleId }

        return filteredEntries
    }

    static func parseLogsToString(
        _ logEntries: [OSLogEntryLog], _ reportFiltering: (OSLogEntryLog) -> String) -> String {
        var report = ""
        logEntries.forEach { entry in
            report.append(reportFiltering(entry) + "\n")
        }
        return report
    }
}

private struct FileHelper {

    static func saveReport(_ report: String, fileName: String) async throws -> URL? {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(for: .documentDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentsURL.appendingPathComponent(fileName)
        try report.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
