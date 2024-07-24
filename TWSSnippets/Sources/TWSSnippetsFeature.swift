import Foundation
import ComposableArchitecture
import TWSSnippet
import TWSCommon
import TWSModels

// swiftlint:disable identifier_name
private let RECONNECT_TIMEOUT: TimeInterval = 3
// swiftlint:enable identifier_name

@Reducer
public struct TWSSnippetsObserverFeature {

    public init() { }

    public var body: some ReducerOf<TWSSnippetsFeature> {
        TWSSnippetsFeature()
            .onChange(of: \.socketURL) { oldValue, newValue in
                Reduce { _, _ in
                    if oldValue == nil && newValue != nil { // TODO: If not connected
                        return .send(.business(.listenForChanges))
                    } else {
                        return .none
                    }
                }
            }
    }
}

@Reducer
public struct TWSSnippetsFeature {

    @ObservableState
    public struct State: Equatable {

        @Shared public internal(set) var snippets: IdentifiedArrayOf<TWSSnippetFeature.State>
        @Shared public internal(set) var source: TWSSource
        public internal(set) var socketURL: URL?

        public init(
            configuration: TWSConfiguration
        ) {
            _snippets = Shared(wrappedValue: [], .snippets(for: configuration))
            _source = Shared(wrappedValue: .api, .source(for: configuration))
        }
    }

    public enum Action {

        @CasePathable
        public enum BusinessAction {
            case load
            case projectLoaded(Result<TWSProject, Error>)
            case snippetAdded(TWSSnippet)
            case listenForChanges
            case delayReconnect
            case reconnectTriggered
            case stopListeningForChanges
            case stopReconnecting
            case snippets(IdentifiedActionOf<TWSSnippetFeature>)
            case set(source: TWSSource)
        }

        case business(BusinessAction)

    }

    @Dependency(\.api) var api
    @Dependency(\.socket) var socket
    @Dependency(\.continuousClock) var clock
    @Dependency(\.configuration) var configuration

    public init() { }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .business(action):
                return _reduce(into: &state, action: action)
            }
        }
        .forEach(\.snippets, action: \.business.snippets) {
            TWSSnippetFeature()
        }
    }

    // MARK: - Helpers

    private func _reduce(into state: inout State, action: Action.BusinessAction) -> Effect<Action> {
        switch action {

        // MARK: - Loading snippets

        case .load:
            logger.info("Load from source: \(state.source)")

            switch state.source {
            case .api:
                break

            case let .customURLs(urls):
                let dummySocketURL = URL(string: "wss://api.thewebsnippet.com")!
                let snippets = _generateCustomSnippets(urls: urls)
                return .send(.business(.projectLoaded(.success(.init(
                    listenOn: dummySocketURL,
                    snippets: snippets
                )))))

            @unknown default:
                break
            }

            return .run { [api] send in
                do {
                    let project = try await api.getProject(configuration())
                    await send(.business(.projectLoaded(.success(project))))
                } catch {
                    await send(.business(.projectLoaded(.failure(error))))
                }
            }

        case let .snippetAdded(snippet):
            let snippetAlreadyInState = !state.snippets.filter({ existingSnippet in
                existingSnippet.snippet.id == snippet.id
            }).isEmpty

            if snippetAlreadyInState {
                logger.info("Snippet already in the state: \(snippet.id)")
            } else {
                state.snippets.append(
                    .init(snippet: snippet, isPrivate: true)
                )
                logger.info("Added snippet: \(snippet.id)")
            }
            return .none

        case let .projectLoaded(.success(project)):
            logger.info("Snippets loaded.")

            var effects = [Effect<Action>]()
            let snippets = project.snippets
            let newOrder = snippets.map(\.id)
            let currentOrder = state.snippets.ids
            let shouldListen = state.socketURL != project.listenOn
            state.socketURL = project.listenOn

            // Update current or add new

            for snippet in snippets {
                if currentOrder.contains(snippet.id) {
                    if state.snippets[id: snippet.id]?.snippet.target != snippet.target {
                        // View needs to be forced refreshed
                        effects.append(
                            .send(.business(.snippets(.element(id: snippet.id, action: .business(.snippetUpdated)))))
                        )
                    }

                    state.snippets[id: snippet.id]?.snippet = snippet
                    logger.info("Updated snippet: \(snippet.id)")
                } else {
                    state.snippets.append(
                        .init(snippet: snippet)
                    )
                    logger.info("Added snippet: \(snippet.id)")
                }
            }

            // Remove old

            for id in currentOrder.subtracting(newOrder) {
                state.snippets.remove(id: id)
                logger.info("Removed snippet: \(id)")
            }

            // Keep sorted
            _sort(basedOn: newOrder, &state)

            return .none

        case let .projectLoaded(.failure(error)):
            if let error = error as? DecodingError {
                logger.err(
                    "Failed to decode snippets: \(error)"
                )
            } else {
                logger.err(
                    "Failed to load snippets: \(error)"
                )
            }

            return .none

        // MARK: - Listening for changes via WebSocket

        case .listenForChanges:
            logger.info("Request to start listening request with source: \(state.source)")
            switch state.source {
            case .api:
                break

            case .customURLs:
                logger.info("Won't listen because the snippets are overridden locally.")
                return .none

            @unknown default:
                break
            }

            guard let url = state.socketURL
            else {
                logger.err("Failed to listen for changes. URL is nil")
                assertionFailure()
                return .none
            }

            return .run { [socket, url] send in
                let connectionID = await socket.get(url)
                let stream: AsyncStream<WebSocketEvent>
                do {
                    stream = try await socket.connect(connectionID)
                } catch {
                    await send(.business(.delayReconnect))
                    return
                }

                do {
                    try await _listen(
                        connectionID: connectionID,
                        stream: stream,
                        send: send
                    )
                } catch {
                    logger.info("Stopped listening: \(error)")
                }

                logger.info("The task used for listening to socket has completed. Closing connection.")
                await socket.closeConnection(connectionID)
            }
            .cancellable(id: CancelID.socket)
            .concatenate(with: .send(.business(.delayReconnect)))

        case .delayReconnect:
            return .run { send in
                do {
                    try await clock.sleep(for: .seconds(RECONNECT_TIMEOUT))
                    logger.info("Reconnect")
                    await send(.business(.reconnectTriggered))
                } catch {
                    logger.err("Reconnecting failed: \(error)")
                }
            }
            .cancellable(id: CancelID.reconnect)

        case .reconnectTriggered:
            state.socketURL = nil
            return .send(.business(.load))

        case .stopListeningForChanges:
            logger.warn("Requested to stop listening for changes")
            return .cancel(id: CancelID.socket)

        case .stopReconnecting:
            logger.warn("Requested to stop reconnecting to the socket")
            return .cancel(id: CancelID.reconnect)

        // MARK: - Other

        case let .set(source):
            logger.info("Set source to: \(source)")
            state.source = source

            switch source {
            case .api, .customURLs:
                return .send(.business(.load))

            @unknown default:
                return .send(.business(.load))
            }

        case .snippets:
            return .none
        }
    }

    // MARK: - Helpers

    private func _sort(basedOn orderedIDs: [UUID], _ state: inout State) {
        var orderDict = [UUID: Int]()
        for (index, id) in orderedIDs.enumerated() {
            orderDict[id] = index
        }

        state.snippets.sort(by: {
            let idx1 = orderDict[$0.id] ?? Int.max
            let idx2 = orderDict[$1.id] ?? Int.max
            return idx1 < idx2
        })
    }

    private func _generateCustomSnippets(urls: [URL]) -> [TWSSnippet] {
        let uuidGenerator = IncrementingUUIDGenerator()
        return urls.map {
            .init(
                id: uuidGenerator(),
                target: $0
            )
        }
    }

    private func _listen(
        connectionID: UUID,
        stream: AsyncStream<WebSocketEvent>,
        send: Send<TWSSnippetsFeature.Action>
    ) async throws {
    mainLoop: for await event in stream {
        switch event {
        case .didConnect:
            logger.info("Did connect \(Date.now)")
            await send(.business(.load))

            do {
                try await socket.listen(connectionID)
            } catch {
                logger.err("Failed to receive a message: \(error)")
                break mainLoop
            }

            if Task.isCancelled { break mainLoop }

        case .didDisconnect:
            logger.info("Did disconnect \(Date())")
            break mainLoop

        case let .receivedMessage(message):
            logger.info("Received a message: \(message)")

            switch message.type {
            case .created, .deleted:
                await send(.business(.load))

            case .updated:
                await send(
                    .business(.snippets(.element(id: message.id, action: .business(.snippetUpdated))))
                )
            }

            do {
                try await socket.listen(connectionID)
            } catch {
                logger.err("Failed to receive a message: \(error)")
                break mainLoop
            }
        }
    }
    }
}

private extension TWSSnippetsFeature {
    enum CancelID: Hashable {
        case socket, reconnect
    }
}

private class IncrementingUUIDGenerator: @unchecked Sendable {

    private var sequence = 0

    func callAsFunction() -> UUID {
        defer {
            self.sequence += 1
        }

        return UUID(self.sequence)
    }
}
