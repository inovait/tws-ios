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
    public let stream: AsyncStream<[TWSSnippet]>

    init(
        store: StoreOf<TWSCoreFeature>,
        stream: AsyncStream<[TWSSnippet]>
    ) {
        self.store = store
        self.stream = stream
        self.initDate = Date()
    }

    // MARK: - Public

    public var snippets: [TWSSnippet] {
        precondition(Thread.isMainThread, "`snippets()` can only be called on main thread")
        return store.snippets.snippets.elements.map(\.snippet)
    }

    public func run(listenForChanges: Bool) {
        store.send(.snippets(.business(.load)))

        if listenForChanges {
            store.send(.snippets(.business(.listenForChanges)))

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                self.store.send(.snippets(.business(.stopListeningForChanges)))
            }
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

    // MARK: - Internal

    func set(height: CGFloat, for snippet: TWSSnippet, displayID: String) {
        assert(Thread.isMainThread)
        store.send(.snippets(.business(
            .snippets(.element(id: snippet.id, action: .business(.update(height: height, forId: displayID))))
        )))
    }
}
