import OSLog

public struct TWSLog {
	private let logger: os.Logger

	public init(subsystem: String = Bundle.main.bundleIdentifier!, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

	public func logMessage(message: String) {
		logger.log("\(message, privacy: .public)")
	}

	public func logInfo(message: String) {
		logger.info("\(message)")
	}

	public func logWarning(message: String) {
		logger.warning("\(message)")
	}

	public func logError(message: String) {
		logger.error("\(message)")
	}

	public func logCritical(message: String) {
		logger.critical("\(message)")
	}
}
