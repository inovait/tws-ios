import OSLog
import TWSModels

public struct TWSLog {
    private let logger: os.Logger?

    public init(category: String) {
        let bundleId = Bundle.main.bundleIdentifier
        if let bundleId {
            logger = Logger(subsystem: bundleId, category: category)
        } else {
            logger = nil
        }
    }

    public func log(_ message: String) {
        logger?.log("\(message, privacy: .public)")
    }

    public func logInfo(_ message: String) {
        logger?.info("\(message)")
    }

    public func logWarn(_ message: String) {
        logger?.warning("\(message)")
    }

    public func logErr(_ message: String) {
        logger?.critical("\(message)")
    }
}
