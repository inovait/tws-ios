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

    func testLogs() async {
        let initDate = Date()

        logManager.err("This is an error", className: "Class 1")
        logManager.info("This is a message", lineNumber: 13)
        logManager.warn("This is a warning", functionName: "Function 1")
        logManager.info("This is an info")

        let exepectedLogResult =
            "This is an error [Class 1, l34]\n" +
            "This is a message [TWSLoggerTests/TWSLoggerTests.swift, l13]\n" +
            "This is a warning [TWSLoggerTests/TWSLoggerTests.swift, l36]\n" +
            "This is an info [TWSLoggerTests/TWSLoggerTests.swift, l37]\n"

        // Fetching the logs and checking if they're present in the log report
        do {
            let logReporter = TWSLogger.LogReporter()
            let logEntries = try await logReporter.getLogsFromLogStore(
                bundleId: "com.apple.dt.xctest.tool",
                date: initDate
            )

            XCTAssertNotNil(logEntries)

            // Seeing if the file is created and if contains out logs
            let fileURL = try await logReporter.generateReport(
                bundleId: "com.apple.dt.xctest.tool",
                date: initDate,
                reportFiltering: { $0.composedMessage }
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
