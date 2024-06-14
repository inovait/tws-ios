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
        let initDate = Date()

        logManager.logErr(message: "This is an error", className: "Class 1")
        logManager.log(message: "This is a message", lineNumber: "13")
        logManager.logWarn(message: "This is a warning", functionName: "Function 1")
        logManager.logInfo(
            message: "This is an info",
            className: "Class 1",
            lineNumber: "13",
            functionName: "Function 1"
        )

        let exepectedLogResult =
            "This is an error Class: Class 1\n" +
            "This is a message LineNumber: 13\n" +
            "This is a warning Function: Function 1\n" +
            "This is an info Class: Class 1 LineNumber: 13 Function: Function 1\n"

        // Fetching the logs and checking if they're present in the log report
        do {
            let logReporter = TWSLogger.LogReporter()
            let logEntries = try await logReporter.getLogsFromLogStore(
                bundleId: "com.apple.dt.xctest.tool",
                initDate: initDate
            )

            XCTAssertNotNil(logEntries)
            XCTAssertNotEqual(0, logEntries!.count)

            let logReport = logReporter.parseLogsToString(logEntries!, logFiltering)

            XCTAssertNotEqual(0, logReport.count)
            XCTAssertEqual(logReport, exepectedLogResult)

            // Seeing if the file is created and if contains out logs
            let fileURL = try await logReporter.generateReport(
                bundleId: "com.apple.dt.xctest.tool",
                initDate: initDate,
                reportFiltering: logFiltering
            )
            XCTAssertNotNil(fileURL)

            if let fileURL = fileURL {
                do {
                    let fileContent = try String(contentsOf: fileURL)
                    XCTAssertEqual(fileContent, exepectedLogResult)
                } catch {
                    XCTFail("Failed to read file content: \(error)")
                }
            }
        } catch {
            XCTFail("Exception received: \(error)")
        }
    }
}
