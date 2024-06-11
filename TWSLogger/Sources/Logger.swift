import OSLog

public struct TWSLog {
    private let logger: os.Logger
    private let category: String

    public init(subsystem: String = Bundle.main.bundleIdentifier!, category: String) {
        self.category = category
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(message: String) {
        logger.log("\(message, privacy: .public)")
        LogReporter.setFirstLogDate(Date())
    }

    public func logInfo(message: String) {
        logger.info("\(message)")
        LogReporter.setFirstLogDate(Date())
    }

    public func logWarn(message: String) {
        logger.warning("\(message)")
        LogReporter.setFirstLogDate(Date())
    }

    public func logErr(message: String) {
        logger.critical("\(message)")
        LogReporter.setFirstLogDate(Date())
    }
}
