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
        initDate: Date,
        reportFiltering: (OSLogEntryLog) -> String
    ) async throws -> URL? {
        let filteredEntries = try await getLogsFromLogStore(bundleId: bundleId, initDate: initDate)
        if let filteredEntries {
            let report = parseLogsToString(filteredEntries, reportFiltering)
            return try await saveReport(report, fileName: "TWS-Logs-\(Date().description).txt")
        }
        throw LoggerError.unableToGetLogs
    }

    func getLogsFromLogStore(bundleId: String, initDate: Date) async throws -> [OSLogEntryLog]? {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(date: Calendar.current.startOfDay(for: initDate.addingTimeInterval(-60 * 60)))
        let entries = try store.getEntries(at: position)

        let filteredEntries = entries
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.subsystem == bundleId }

        return filteredEntries
    }

    func parseLogsToString(
        _ logEntries: [OSLogEntryLog],
        _ reportFiltering: (OSLogEntryLog) -> String
    ) -> String {
        var report = ""
        logEntries.forEach { entry in
            report.append(reportFiltering(entry) + "\n")
        }
        return report
    }

    func saveReport(_ report: String, fileName: String) async throws -> URL? {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(for: .documentDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentsURL.appendingPathComponent(fileName)
        try report.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
