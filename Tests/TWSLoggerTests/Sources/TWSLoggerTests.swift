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

        let expectedLogResult =
            "This is an error [Class 1, l38]\n" +
            "This is a message [TWSLoggerTests/TWSLoggerTests.swift, l13]\n" +
            "This is a warning [TWSLoggerTests/TWSLoggerTests.swift, l40]\n" +
            "This is an info [TWSLoggerTests/TWSLoggerTests.swift, l41]\n"

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

                    XCTAssertEqual(
                        fileContent,
                        expectedLogResult,
                        """
                        Actual: \(fileContent.description)
                        -------
                        Expected: \(expectedLogResult.description)
                        """
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
