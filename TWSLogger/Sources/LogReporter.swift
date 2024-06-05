//
//  LogBuffer.swift
//  TWSLogger
//
//  Created by Luka Kit on 4. 6. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public struct LogReporter {

    private static var logBuffer: [String] = []
    private static let bufferLimit = 100

    public static func addToBuffer(_ message: String, _ category: String, _ severity: String) {
        let logTimestamp = Date().description
        logBuffer.append("\(logTimestamp) - \(category) - \(severity): \(message)")
        if logBuffer.count > bufferLimit {
            logBuffer.removeFirst()
        }
    }

    public static func generateReport() -> URL? {
        let logs = logBuffer
        var report = "Log Report\n\n"
        for log in logs {
            report += "\(log)\n"
        }
        return FileHelper.saveReport(report, fileName: "TWS-Logs-\(Date().description).txt")
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
