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
import TWSModels

public struct LogReporter: Sendable {

    public init() {}

    public func generateReport(
        bundleId: String,
        date: Date,
        reportFiltering: @Sendable (OSLogEntryLog) -> String
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
        _ reportFiltering: @Sendable (OSLogEntryLog) -> String,
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
            throw LoggerError.unableToWriteToLogFile
        }
    }

    func openFile(fileName: String) async throws -> URL? {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            FileManager.default.createFile(atPath: tempURL.path, contents: nil, attributes: nil)
            
            return tempURL
        }
        
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(for: .documentDirectory,
            in: .userDomainMask, appropriateFor: nil, create: false)
        let fileURL = documentsURL.appendingPathComponent(fileName)
        fileManager.createFile(atPath: fileURL.path(), contents: nil)
        return fileURL
    }
}
