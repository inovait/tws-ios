import OSLog

public struct TWSLog {
    private let logger: os.Logger
    private let category: String

    public init(subsystem: String = Bundle.main.bundleIdentifier!, category: String) {
        self.category = category
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func logMessage(message: String) {
        logger.log("\(message, privacy: .public)")
        LogReporter.addToBuffer(message, category, "debug")
    }

    public func logInfo(message: String) {
        logger.info("\(message)")
        LogReporter.addToBuffer(message, category, "info")
    }

    public func logWarning(message: String) {
        logger.warning("\(message)")
        LogReporter.addToBuffer(message, category, "warning")
    }

    public func logError(message: String) {
        logger.critical("\(message)")
        LogReporter.addToBuffer(message, category, "error")
    }
}
