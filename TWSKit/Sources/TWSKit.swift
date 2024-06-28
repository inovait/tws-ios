import Foundation
import SwiftUI
import TWSModels
import OSLog
@_implementationOnly import TWSCore
@_implementationOnly import ComposableArchitecture
@_implementationOnly import TWSLogger

public class TWSManager {

    private let initDate: Date
    let store: StoreOf<TWSCoreFeature>
    public let snippetsStream: AsyncStream<[TWSSnippet]>
    public let qrSnippetStream: AsyncStream<TWSSnippet?>

    init(
        store: StoreOf<TWSCoreFeature>,
        snippetsStream: AsyncStream<[TWSSnippet]>,
        qrSnippetStream: AsyncStream<TWSSnippet?>
    ) {
        self.store = store
        self.snippetsStream = snippetsStream
        self.qrSnippetStream = qrSnippetStream
        self.initDate = Date()
    }

    // MARK: - Public

    public var snippets: [TWSSnippet] {
        precondition(Thread.isMainThread, "`snippets()` can only be called on main thread")
        return store.snippets.snippets.elements.map(\.snippet)
    }

    public var qrLoadedSnippet: TWSSnippet? {
        precondition(Thread.isMainThread, "`loadedSnippet()` can only be called on main thread")
        return store.universalLinks.loadedSnippet
    }

    public func run(listenForChanges: Bool) {
        store.send(.snippets(.business(.load)))

        if listenForChanges {
            store.send(.snippets(.business(.listenForChanges)))
        }
    }

    public func set(source: TWSSource) {
        store.send(.snippets(.business(.set(source: source))))
    }

    public func getLogsReport(reportFiltering: (OSLogEntryLog) -> String) async throws -> URL? {
        let bundleId = Bundle.main.bundleIdentifier
        if let bundleId {
            let logReporter = LogReporter()
            return try await logReporter.generateReport(
                bundleId: bundleId,
                date: initDate.addingTimeInterval(-60),
                reportFiltering: reportFiltering
            )
        }
        throw LoggerError.bundleIdNotAvailable
    }

    public func handleIncomingUrl(_ url: URL) {
        store.send(.universalLinks(.business(.loadSnippet(url))))
    }

    public func clearQRSnippet() {
        store.send(.universalLinks(.business(.clearLoadedSnippet)))
    }

    // MARK: - Internal

    func set(height: CGFloat, for snippet: TWSSnippet, displayID: String) {
        assert(Thread.isMainThread)
        store.send(.snippets(.business(
            .snippets(.element(id: snippet.id, action: .business(.update(height: height, forId: displayID))))
        )))
    }
}
