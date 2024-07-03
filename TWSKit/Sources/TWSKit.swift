import Foundation
import SwiftUI
import TWSModels
@_implementationOnly import TWSCore
@_implementationOnly import ComposableArchitecture
@_implementationOnly import TWSLogger

public class TWSManager {

    private let initDate: Date
    let store: StoreOf<TWSCoreFeature>
    public let snippetsStream: AsyncStream<[TWSSnippet]>
    public let qrSnippetStream: AsyncStream<TWSSnippet?>
    let snippetHeightProvider: SnippetHeightProvider
    let navigationProvider: NavigationProvider

    init(
        store: StoreOf<TWSCoreFeature>,
        snippetsStream: AsyncStream<[TWSSnippet]>,
        qrSnippetStream: AsyncStream<TWSSnippet?>
    ) {
        self.store = store
        self.snippetsStream = snippetsStream
        self.qrSnippetStream = qrSnippetStream
        self.initDate = Date()
        self.snippetHeightProvider = SnippetHeightProviderImpl()
        self.navigationProvider = NavigationProviderImpl()
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
        precondition(Thread.isMainThread, "`run(listenForChanges:)` can only be called on main thread")
        store.send(.snippets(.business(.load)))

        if listenForChanges {
            store.send(.snippets(.business(.listenForChanges)))
        }
    }

    public func goBack(snippet: TWSSnippet, displayID: String) {
        NotificationBuilder.send(
            Notification.Name.Navigation.Back,
            snippet: snippet,
            displayID: displayID
        )
    }

    public func goForward(snippet: TWSSnippet, displayID: String) {
        NotificationBuilder.send(
            Notification.Name.Navigation.Forward,
            snippet: snippet,
            displayID: displayID
        )
    }

    public func set(source: TWSSource) {
        precondition(Thread.isMainThread, "`set(source:)` can only be called on main thread")

        // Reset height store
        snippetHeightProvider.reset()

        // Send to store
        store.send(.snippets(.business(.set(source: source))))
    }

    public func getLogsReport(reportFiltering: @Sendable @escaping (TWSLogEntryLog) -> String) async throws -> URL? {
        precondition(Thread.isMainThread, "`getLogsReport(reportFiltering:)` can only be called on main thread")

        let bundleId = Bundle.main.bundleIdentifier
        if let bundleId {
            let logReporter = LogReporter()
            return try await logReporter.generateReport(
                bundleId: bundleId,
                date: initDate.addingTimeInterval(-60),
                reportFiltering: { input in
                    let log = TWSLogEntryLog(from: input)
                    return reportFiltering(log)
                }
            )
        }
        throw LoggerError.bundleIdNotAvailable
    }

    public func handleIncomingUrl(_ url: URL) {
        store.send(.universalLinks(.business(.onUniversalLink(url))))
    }

    public func clearQRSnippet() {
        store.send(.universalLinks(.business(.clearLoadedSnippet)))
    }

    // MARK: - Internal

    func set(height: CGFloat, for snippet: TWSSnippet, displayID: String) {
        assert(Thread.isMainThread)
        guard
            store.snippets.snippets[id: snippet.id] != nil
        else {
            return
        }
        store.send(.snippets(.business(
            .snippets(.element(id: snippet.id, action: .business(.update(height: height, forId: displayID))))
        )))
    }
}
