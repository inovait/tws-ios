import OSLog
import TWSModels

public struct TWSLog {
    private let logger: os.Logger

    public init(category: String) {
        let bundleId = Bundle.main.bundleIdentifier
        if let bundleId {
            logger = Logger(subsystem: bundleId, category: category)
        } else {
            preconditionFailure("Unable to create a logger without the bundle ID available")
        }
    }

    public func log(
        message: String,
        className: String? = #fileID,
        lineNumber: Int? = #line,
        functionName: String? = #function
    ) {
        logger.log("\(createLogMessage(message, className, lineNumber, functionName))")
    }

    public func logInfo(
        message: String,
        className: String? = #fileID,
        lineNumber: Int? = #line,
        functionName: String? = #function
    ) {
        logger.info("\(createLogMessage(message, className, lineNumber, functionName))")
    }

    public func logWarn(
        message: String,
        className: String? = #fileID,
        lineNumber: Int? = #line,
        functionName: String? = #function
    ) {
        logger.warning("\(createLogMessage(message, className, lineNumber, functionName))")
    }

    public func logErr(
        message: String,
        className: String? = #fileID,
        lineNumber: Int? = #line,
        functionName: String? = #function
    ) {
        logger.critical("\(createLogMessage(message, className, lineNumber, functionName))")
    }

    private func createLogMessage(
        _ message: String,
        _ className: String?,
        _ lineNumber: Int?,
        _ functionName: String?
    ) -> String {
        var log = message
        if let className {
            log.append(" Class: \(className)")
        }
        if let lineNumber {
            log.append(" LineNumber: \(lineNumber)")
        }
        if let functionName {
            log.append(" Function: \(functionName)")
        }
        return log
    }
}
