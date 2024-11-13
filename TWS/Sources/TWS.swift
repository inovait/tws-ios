import Foundation
import SwiftUI
import Combine
@_exported import TWSModels
internal import TWSCore
internal import ComposableArchitecture
internal import TWSLogger
internal import TWSSnippets
internal import TWSSnippet

/// A class that handles all the communication between your app and the SDK's functionalities
@MainActor
@Observable
public final class TWSManager: Identifiable {

    public let configuration: TWSConfiguration

    let observer: AnyPublisher<TWSStreamEvent, Never>
    let store: StoreOf<TWSCoreFeature>
    let snippetHeightProvider: SnippetHeightProvider
    let navigationProvider: NavigationProvider

    private let initDate: Date
    private let _id = UUID().uuidString.suffix(4)
    private var _stateSync: AnyCancellable?
    private var isSetup = false

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
        self.snippets = store.snippets.snippets.elements.map(\.snippet)

        logger.info("INIT TWSManager \(_id)")
        _syncState()
    }

    deinit {
        logger.info("DEINIT TWSManager \(_id)")
        MainActor.assumeIsolated { TWSFactory.destroy(configuration: configuration) }
    }

    private func _syncState() {
        _stateSync = observer
            .compactMap {
                switch $0 {
                case .snippetsUpdated: return ()
                case .universalLinkSnippetLoaded: return nil
                }
            }
            .sink(receiveValue: { [weak self] _ in
                guard let weakSelf = self else { return }
                weakSelf.snippets = weakSelf.store.snippets.snippets.filter(\.isVisible).elements.map(\.snippet)
            })
    }

    // MARK: - Public

    /// A getter for the list of loaded snippets
    public internal(set) var snippets: [TWSSnippet]

    /// A function that starts loading snippets and listen for changes
    public func run() {
        precondition(Thread.isMainThread, "`run()` can only be called on main thread")
        defer { isSetup = true }
        guard !isSetup else { return }
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

    /// A function that sets the location from where the snippets are going to be loaded
    /// - Parameter source: Define the source of the snippets
    public func set(source: TWSSource) {
        precondition(Thread.isMainThread, "`set(source:)` can only be called on main thread")

        // Reset height store
        snippetHeightProvider.reset()

        // Send to store
        store.send(.snippets(.business(.set(source: source))))
    }

    /// Defines a custom set of local properties that will be injected into the ``TWSView``.
    /// - Parameters:
    ///   - localProps: A dictionary containing the local properties to inject.
    ///   - id: The identifier of the snippet to associate with this dictionary.
    public func set(localProps: [String: TWSSnippet.Props], to id: TWSSnippet.ID) {
        precondition(Thread.isMainThread, "`set(customProps:,to:)` can only be called on main thread")
        store.send(.snippets(.business(.setLocalProps(props: (id, localProps)))))
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
}
