//
//  TWSLoggerTests.swift
//  TWSLoggerTests
//
//  Created by Luka Kit on 7. 6. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import XCTest
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

        // Adding 4 logs and checking if the firstLogDate is set correctly
        XCTAssertNil(TWSLogger.LogReporter.firstLogDate)

        logManager.logError(message: "This is an error")
        logManager.logMessage(message: "This is a message")
        logManager.logWarning(message: "This is a warning")
        logManager.logInfo(message: "This is an info")

        sleep(1)

        XCTAssertNotNil(TWSLogger.LogReporter.firstLogDate)

        // Fetching the logs and checking if they're present in the log report
        let logEntries = TWSLogger.LogReporter.getLogsFromLogStore(filteredSubsytem: "com.apple.dt.xctest.tool")

        XCTAssertNotNil(logEntries)
        XCTAssertNotEqual(0, logEntries!.count)

        let logReport = TWSLogger.LogReporter.parseLogsToString(logEntries!)

        XCTAssertNotEqual(0, logReport.count)
        XCTAssertTrue(logReport.contains("This is an error"))
        XCTAssertTrue(logReport.contains("This is a message"))
        XCTAssertTrue(logReport.contains("This is a warning"))
        XCTAssertTrue(logReport.contains("This is an info"))

        // Seeing if the file is created and if contains out logs
        let fileURL = TWSLogger.LogReporter.generateReport(filteredSubsytem: "com.apple.dt.xctest.tool")
        XCTAssertNotNil(fileURL)

        if let fileURL = fileURL {
            do {
                let fileContent = try String(contentsOf: fileURL)
                XCTAssertTrue(fileContent.contains("This is an error"))
                XCTAssertTrue(fileContent.contains("This is a message"))
                XCTAssertTrue(fileContent.contains("This is a warning"))
                XCTAssertTrue(fileContent.contains("This is an info"))
            } catch {
                XCTFail("Failed to read file content: \(error)")
            }
        }
    }
}
