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

    /// A getter for the list of loaded snippets
    public internal(set) var snippets: TWSOutcome<[TWSSnippet]>

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

        let items = store.snippets.snippets.elements.map(\.snippet)
        let state = store.snippets.state
        self.snippets = .init(
            items: items,
            state: state
        )

        logger.info("INIT TWSManager \(_id)")
        _syncState()
        _run()
    }

    deinit {
        logger.info("DEINIT TWSManager \(_id)")
        MainActor.assumeIsolated { TWSFactory.destroy(configuration: configuration) }
    }

    // MARK: - Public

    public func forceRefresh() {
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

    // MARK: - Helpers

    private func _run() {
        precondition(Thread.isMainThread, "`run()` can only be called on main thread")
        defer { isSetup = true }
        guard !isSetup else { return }
        store.send(.snippets(.business(.load)))
    }

    private func _syncState() {
        _stateSync = observer
            .compactMap {
                switch $0 {
                case .snippetsUpdated: return _React.snippets
                case .universalLinkSnippetLoaded: return nil
                case .stateChanged: return .state
                }
            }
            .sink(receiveValue: { [weak self] react in
                guard let weakSelf = self else { return }
                switch react {
                case .snippets:
                    let items = weakSelf.store.snippets.snippets.filter(\.isVisible).elements.map(\.snippet)
                    weakSelf.snippets.items = items

                case .state:
                    weakSelf.snippets.state = weakSelf.store.snippets.state
                }
            })
    }
}

private enum _React { case snippets, state }
