//
//  TWSLoggerTests.swift
//  TWSLoggerTests
//
//  Created by Luka Kit on 7. 6. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import XCTest
import OSLog
@testable import TWSLogger

final class TWSLoggerTests: XCTestCase {

    var logManager: TWSLog!

    override func setUpWithError() throws {
        try super.setUpWithError()
        logManager = TWSLog(category: "testSuite")
    }

    override func tearDownWithError() throws {
        logManager = nil
        try super.tearDownWithError()
    }

    private func logFiltering(entry: OSLogEntry) -> String {
        return entry.composedMessage
    }

    func testLogs() async {

        // Adding 4 logs a

        logManager.logErr("This is an error")
        logManager.log("This is a message")
        logManager.logWarn("This is a warning")
        logManager.logInfo("This is an info")

        // Fetching the logs and checking if they're present in the log report
        do {
            let logEntries = try await TWSLogger.LogReporter.getLogsFromLogStore(bundleId: "com.apple.dt.xctest.tool")

            XCTAssertNotNil(logEntries)
            XCTAssertNotEqual(0, logEntries!.count)

            let logReport = TWSLogger.LogReporter.parseLogsToString(logEntries!, logFiltering)

            XCTAssertNotEqual(0, logReport.count)
            XCTAssertEqual(logReport,
                "This is an error\nThis is a message\nThis is a warning\nThis is an info\n"
            )

            // Seeing if the file is created and if contains out logs
            let fileURL = try await TWSLogger.LogReporter.generateReport(
                bundleId: "com.apple.dt.xctest.tool", reportFiltering: logFiltering)
            XCTAssertNotNil(fileURL)

            if let fileURL = fileURL {
                do {
                    let fileContent = try String(contentsOf: fileURL)
                    XCTAssertEqual(fileContent,
                        "This is an error\nThis is a message\nThis is a warning\nThis is an info\n"
                    )
                } catch {
                    XCTFail("Failed to read file content: \(error)")
                }
            }
        } catch {
            XCTFail("Exception received: \(error)")
        }
    }
}
