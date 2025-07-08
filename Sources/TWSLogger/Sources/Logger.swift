import OSLog
import TWSModels

public struct TWSLog: Sendable {

    private let logger: os.Logger
    let bundleId: String!

    public init(category: String) {
        
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            bundleId = "com.apple.dt.xctest.tool"
        } else {
            bundleId = Bundle.main.bundleIdentifier
        }
        
        if let bundleId {
            logger = Logger(subsystem: bundleId, category: category)
        } else {
            preconditionFailure("Unable to create a logger without the bundle ID available")
        }
    }

    public func debug(
        _ message: String,
        className: String = #fileID,
        lineNumber: Int = #line,
        functionName: String = #function
    ) {
        logger.debug("\(createLogMessage(message, className, lineNumber, functionName), privacy: .public)")
    }

    public func info(
        _ message: String,
        className: String = #fileID,
        lineNumber: Int = #line,
        functionName: String = #function
    ) {
        logger.info("\(createLogMessage(message, className, lineNumber, functionName), privacy: .public)")
    }

    public func warn(
        _ message: String,
        className: String = #fileID,
        lineNumber: Int = #line,
        functionName: String = #function
    ) {
        logger.warning("\(createLogMessage(message, className, lineNumber, functionName), privacy: .public)")
    }

    public func err(
        _ message: String,
        className: String = #fileID,
        lineNumber: Int = #line,
        functionName: String = #function
    ) {
        logger.critical("\(createLogMessage(message, className, lineNumber, functionName), privacy: .public)")
    }

    private func createLogMessage(
        _ message: String,
        _ className: String,
        _ lineNumber: Int,
        _ functionName: String
    ) -> String {
        var log = message
        log.append(" [\(className), l\(lineNumber)]")
        return log
    }
}
