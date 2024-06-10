//
//  LogBuffer.swift
//  TWSLogger
//
//  Created by Luka Kit on 4. 6. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import OSLog

public struct LogReporter {

    internal static var firstLogDate: Date?

    public static func setFirstLogDate(_ date: Date) {
        if firstLogDate == nil {
            firstLogDate = date
        }
    }

    public static func generateReport(filteredSubsytem: String = "com.inova.tws") -> URL? {
        let filteredEntries = getLogsFromLogStore(filteredSubsytem: filteredSubsytem)
        if let filteredEntries {
            let report = parseLogsToString(filteredEntries)
            return FileHelper.saveReport(report, fileName: "TWS-Logs-\(Date().description).txt")
        }
        return nil
    }

    internal static func getLogsFromLogStore(filteredSubsytem: String = "com.inova.tws") -> [OSLogEntryLog]? {
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(date: firstLogDate!)
            let entries = try store.getEntries(at: position)

            let filteredEntries = entries
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == filteredSubsytem }

            return filteredEntries
        } catch {
            return nil
        }
    }

    internal static func parseLogsToString(_ logEntries: [OSLogEntryLog]) -> String {
        var report = ""
        logEntries.forEach { entry in
            report.append("\(entry.date.description) - \(entry.category): \(entry.composedMessage)")
        }
        return report
    }
}

private struct FileHelper {

    static func saveReport(_ report: String, fileName: String) -> URL? {
        let fileManager = FileManager.default
        do {
            let documentsURL = try fileManager.url(for: .documentDirectory,
                                                   in: .userDomainMask, appropriateFor: nil, create: true)
            let fileURL = documentsURL.appendingPathComponent(fileName)
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
