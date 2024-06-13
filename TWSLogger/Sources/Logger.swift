import OSLog

public struct TWSLog {
    private let logger: os.Logger
    private let category: String

    public init(subsystem: String = Bundle.main.bundleIdentifier!, category: String) {
        self.category = category
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(_ message: String) {
        logger.log("\(message, privacy: .public)")
    }

    public func logInfo(_ message: String) {
        logger.info("\(message)")
    }

    public func logWarn(_ message: String) {
        logger.warning("\(message)")
    }

    public func logErr(_ message: String) {
        logger.critical("\(message)")
    }
}
