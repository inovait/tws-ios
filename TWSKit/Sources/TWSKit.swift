import Foundation
import SwiftUI
@_exported import TWSModels
@_implementationOnly import TWSCore
@_implementationOnly import ComposableArchitecture
@_implementationOnly import TWSLogger

/// A class that handles all the communication between your app and the SDK's functionalities
public class TWSManager {

    private let initDate: Date
    let store: StoreOf<TWSCoreFeature>
    public let events: AsyncStream<TWSStreamEvent>
    let snippetHeightProvider: SnippetHeightProvider
    let navigationProvider: NavigationProvider

    init(
        store: StoreOf<TWSCoreFeature>,
        events: AsyncStream<TWSStreamEvent>
    ) {
        self.store = store
        self.events = events
        self.initDate = Date()
        self.snippetHeightProvider = SnippetHeightProviderImpl()
        self.navigationProvider = NavigationProviderImpl()
    }

    // MARK: - Public

    /// A getter for the list of loaded snippets
    public var snippets: [TWSSnippet] {
        precondition(Thread.isMainThread, "`snippets()` can only be called on main thread")
        return store.snippets.snippets.elements.map(\.snippet)
    }

    /// A function that starts loading snippets and listen for changes
    public func run() {
        precondition(Thread.isMainThread, "`run(listenForChanges:)` can only be called on main thread")
        store.send(.snippets(.business(.load)))
    }

    /// A function that load the previous snippet in the list
    /// - Parameters:
    ///   - snippet: The snippet that is currently showing
    ///   - displayID: The displayID you've set in your ``TWSView``
    public func goBack(snippet: TWSSnippet, displayID: String) {
        NotificationBuilder.send(
            Notification.Name.Navigation.Back,
            snippet: snippet,
            displayID: displayID
        )
    }

    /// A function that load the next snippet in the list
    /// - Parameters:
    ///   - snippet: The snippet that is currently showing
    ///   - displayID: The displayID you've set in your ``TWSView``
    public func goForward(snippet: TWSSnippet, displayID: String) {
        NotificationBuilder.send(
            Notification.Name.Navigation.Forward,
            snippet: snippet,
            displayID: displayID
        )
    }

    /// A function that sets the location from where the snippets are going to be loaded
    /// - Parameter source: Define the source of the snippets
    public func set(source: TWSSource) {
        precondition(Thread.isMainThread, "`set(source:)` can only be called on main thread")

        // Reset height store
        snippetHeightProvider.reset()

        // Send to store
        store.send(.snippets(.business(.set(source: source))))
    }

    /// An async function that gathers all the logs in the current session
    /// - Parameter reportFiltering: A function that lets you define which data of the logs do you want displayed
    /// - Returns: An URL of the file that has all the logs written inside
    public func getLogsReport(reportFiltering: @Sendable @escaping (TWSLogEntryLog) -> String) async throws -> URL? {

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

    /// A function you use to handle universal links regarding snippets
    /// - Parameter url: The received universal link
    public func handleIncomingUrl(_ url: URL) {
        precondition(Thread.isMainThread, "`handleIncomingUrl(url:)` can only be called on main thread")
        store.send(.universalLinks(.business(.onUniversalLink(url))))
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
