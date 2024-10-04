import Foundation
import SwiftUI
import Combine
@_exported import TWSModels
internal import TWSCore
internal import ComposableArchitecture
internal import TWSLogger

/// A class that handles all the communication between your app and the SDK's functionalities
@MainActor
public final class TWSManager: Identifiable {

    let observer: AnyPublisher<TWSStreamEvent, Never>
    let store: StoreOf<TWSCoreFeature>
    let configuration: TWSConfiguration
    let snippetHeightProvider: SnippetHeightProvider
    let navigationProvider: NavigationProvider

    private let initDate: Date
    private let _id = UUID().uuidString.suffix(4)
    private var clearedPopupSnippets: [TWSSnippet] = []
    private var hiddenSnippets: [TWSSnippet] = []

    init(
        store: StoreOf<TWSCoreFeature>,
        observer: AnyPublisher<TWSStreamEvent, Never>,
        configuration: TWSConfiguration
    ) {
        self.store = store
        self.observer = observer.share().eraseToAnyPublisher()
        self.configuration = configuration
        self.initDate = Date()
        self.snippetHeightProvider = SnippetHeightProviderImpl()
        self.navigationProvider = NavigationProviderImpl()

        logger.info("INIT TWSManager \(_id)")
    }

    deinit {
        logger.info("DEINIT TWSManager \(_id)")
        MainActor.assumeIsolated { TWSFactory.destroy(configuration: configuration) }
    }

    // MARK: - Public
    public func addClearedPopup(_ snippet: TWSSnippet) {
        self.clearedPopupSnippets.append(snippet)
    }

    public func canShowPopupSnippet(_ snippet: TWSSnippet) -> Bool {
        return !clearedPopupSnippets.contains(snippet)
    }

    /// A getter for the list of loaded snippets
    public var tabSnippets: [TWSSnippet] {
        precondition(Thread.isMainThread, "`tabSnippets()` can only be called on main thread")
        var tabSnippets = store.snippets.snippets.elements.map(\.snippet).filter { snippet in
            return TWSSnippet.SnippetType(snippetType: snippet.type) == .tab
        }
        if let serverTime = store.snippets.serverDate {
            tabSnippets.forEach { snippet in
                setupVisibilityTimer(serverTime: serverTime, snippet: snippet)
            }
        }

        return tabSnippets.filter { snippet in
            return !hiddenSnippets.contains(snippet)
        }
    }

    public var popupSnippets: [TWSSnippet] {
        precondition(Thread.isMainThread, "`popupSnippets()` can only be called on main thread")
        let popupSnippets = store.snippets.snippets.elements.map(\.snippet).filter { snippet in
            return TWSSnippet.SnippetType(snippetType: snippet.type) == .popup && canShowPopupSnippet(snippet)
        }
        if let serverTime = store.snippets.serverDate {
            popupSnippets.forEach { snippet in
                setupVisibilityTimer(serverTime: serverTime, snippet: snippet)
            }
        }

        return popupSnippets.filter { snippet in
            return !hiddenSnippets.contains(snippet)
        }
    }

    /// A function that starts loading snippets and listen for changes
    public func run() {
        precondition(Thread.isMainThread, "`run()` can only be called on main thread")
        hiddenSnippets = []
        store.send(.snippets(.business(.load)))
    }

    /// Start listening for updates. Check ``TWSStreamEvent`` enum for details.
    /// It is automatically canceled when the parent task is cancelled.
    /// - Parameter onEvent: A callback triggered for every update
    public func observe(onEvent: @MainActor @Sendable @escaping (TWSStreamEvent) -> Void) async {
        precondition(Thread.isMainThread, "`observe` can only be called on main thread")
        let adapter = CombineToAsyncStreamAdapter(upstream: observer)
        await adapter.listen(onEvent: onEvent)
    }

    /// A function that invokes the browser's back functionality
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

    /// A function that invokes the browser's forward functionality
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

    // MARK: - Private

    private func hideSnippet(_ snippet: TWSSnippet) {
        if let index = hiddenSnippets.firstIndex(of: snippet) {
            logger.err("Trying to hide a snippet that is already in the hidden snippets list.")
        } else {
            hiddenSnippets.append(snippet)
        }
    }

    private func showSnippet(_ snippet: TWSSnippet) {
        if let index = hiddenSnippets.firstIndex(of: snippet) {
            hiddenSnippets.remove(at: index)
        } else {
            logger.err("Trying to show a snippet that is not in the hidden snippets list.")
        }
    }

    private func setupVisibilityTimer(serverTime: Date, snippet: TWSSnippet) {
        if let snippetVisibility = snippet.visibility {
            if let fromUtc = snippetVisibility.fromUtc {
                if serverTime < fromUtc {
                    hideSnippet(snippet)
                } else {
                    let duration = fromUtc.timeIntervalSince(serverTime)
                    let timerTask = SnippetVisibiltyTimer()
                    Task {
                        await timerTask.startTimer(queueLabel: "from-\(snippet.id)", duration: duration) { [weak self] in
                            self?.showSnippet(snippet)
                        }

                        await timerTask.shutdown()
                    }
                }
            }
            if let untilUtc = snippetVisibility.untilUtc {
                if serverTime > untilUtc {
                    hideSnippet(snippet)
                } else {
                    let duration = serverTime.timeIntervalSince(untilUtc)
                    let timerTask = SnippetVisibiltyTimer()
                    Task {
                        await timerTask.startTimer(queueLabel: "until-\(snippet.id)", duration: duration) { [weak self] in
                            self?.hideSnippet(snippet)
                        }

                        await timerTask.shutdown()
                    }
                }
            }
        } else {
            return
        }
    }
}
